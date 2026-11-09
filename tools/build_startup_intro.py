"""Bake the selected V08 into smooth, reproducible GML motion samples (standard library only)."""
import bisect
import json
import math
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'tools/fixtures/startup-intro-v08.json'
TARGET=ROOT/'RandomForest/scripts/scriptIntroFirefly/scriptIntroFirefly.gml'
HZ=240


def hermite(a,b,ma,mb,u):
    """Interpolate positions and their shared tangents without introducing a corner."""
    return (2*u**3-3*u*u+1)*a+(u**3-2*u*u+u)*ma+(-2*u**3+3*u*u)*b+(u**3-u*u)*mb


def derivative(a,b,ma,mb,u):
    """Differentiate the cubic for an exact direction at each sampled position."""
    return (6*u*u-6*u)*a+(3*u*u-4*u+1)*ma+(-6*u*u+6*u)*b+(3*u*u-2*u)*mb


def integral(a,b,ma,mb,u):
    """Integrate one Hermite polynomial analytically, including a partial interval."""
    return (.5*u**4-u**3+u)*a+(.25*u**4-2*u**3/3+.5*u*u)*ma+(-.5*u**4+u**3)*b+(.25*u**4-u**3/3)*mb


def slopes(xs,ys):
    """Use monotone cubic slopes to smooth authored speed controls without overshoot."""
    h=[b-a for a,b in zip(xs,xs[1:])]
    d=[(b-a)/width for a,b,width in zip(ys,ys[1:],h)]
    result=[d[0]]
    for i in range(1,len(xs)-1):
        if d[i-1]*d[i]<=0:result.append(0)
        else:
            w1=2*h[i]+h[i-1];w2=h[i]+2*h[i-1]
            result.append((w1+w2)/(w1/d[i-1]+w2/d[i]))
    result.append(d[-1])
    return result


class Flight:
    """Join the selected curves once, keeping every waypoint and both phase durations."""

    def __init__(self,scene):
        """Build one spatial spline and a positive C1 speed envelope with exact phase distances."""
        self.moves=sorted((e for e in scene['events'] if e['type']=='move' and e['enabled']),key=lambda e:e['start'])
        first,second=self.moves
        assert first['points'][-1]==second['points'][0]
        assert abs(first['start']+first['duration']-second['start'])<1e-8
        self.points=first['points']+second['points'][1:]
        self.join=len(first['points'])-1
        self.tangents=[]
        for i in range(len(self.points)):
            prev=self.points[max(0,i-1)];nxt=self.points[min(len(self.points)-1,i+1)]
            self.tangents.append([(nxt[a]-prev[a])*.5 for a in range(2)])
        self.arc=[0.0];self.parameters=[0.0];last=self.point(0)
        for i in range(1,(len(self.points)-1)*1000+1):
            p=i/1000;current=self.point(p)
            self.arc.append(self.arc[-1]+math.dist(last,current));self.parameters.append(p);last=current
        self.boundary=self.arc[self.join*1000];self.length=self.arc[-1]
        self.lengths=[self.boundary,self.length-self.boundary]
        self.times=[];self.values=[];raw=[]
        for move,length in zip(self.moves,self.lengths):
            controls=move['speed'];area=sum((b[0]-a[0])*(a[1]+b[1])/2 for a,b in zip(controls,controls[1:]))
            values=[length/move['duration']*v/area for _,v in controls];raw.append(values)
        shared=2*raw[0][-1]*raw[1][0]/(raw[0][-1]+raw[1][0])
        self.original_join_speeds=[raw[0][-1],raw[1][0]]
        raw[0][-1]=shared;raw[1][0]=shared
        for i,(move,values) in enumerate(zip(self.moves,raw)):
            for j,((fraction,_),value) in enumerate(zip(move['speed'],values)):
                if i and j==0:continue
                self.times.append(move['start']+fraction*move['duration']);self.values.append(value)
        self.slopes=slopes(self.times,self.values)
        self.corrections=[]
        for move,length in zip(self.moves,self.lengths):
            self.corrections.append(length-self.raw_distance(move['start'],move['start']+move['duration']))
        self.start=self.moves[0]['start'];self.stop=self.moves[-1]['start']+self.moves[-1]['duration']

    def point(self,p):
        """Evaluate the joined cardinal curve in its spatial parameter."""
        i=min(len(self.points)-2,max(0,int(p)));u=p-i
        return [hermite(self.points[i][a],self.points[i+1][a],self.tangents[i][a],self.tangents[i+1][a],u) for a in range(2)]

    def direction(self,p):
        """Normalize the shared analytic tangent for continuous velocity vectors."""
        i=min(len(self.points)-2,max(0,int(p)));u=p-i
        v=[derivative(self.points[i][a],self.points[i+1][a],self.tangents[i][a],self.tangents[i+1][a],u) for a in range(2)]
        length=math.hypot(*v)
        return [n/length for n in v]

    def raw_distance(self,start,end):
        """Integrate the smooth speed curve over any authored phase."""
        total=0
        for i in range(len(self.times)-1):
            a,b=self.times[i:i+2];h=b-a;lo=max(a,start);hi=min(b,end)
            if hi<=lo:continue
            args=[self.values[i],self.values[i+1],h*self.slopes[i],h*self.slopes[i+1]]
            total+=h*(integral(*args,(hi-a)/h)-integral(*args,(lo-a)/h))
        return total

    def speed(self,t):
        """Correct phase travel with a zero-value, zero-slope bump at each shared boundary."""
        i=min(len(self.times)-2,max(0,bisect.bisect_right(self.times,t)-1));a,b=self.times[i:i+2];h=b-a
        v=hermite(self.values[i],self.values[i+1],h*self.slopes[i],h*self.slopes[i+1],(t-a)/h)
        phase=0 if t<=self.moves[1]['start'] else 1;move=self.moves[phase];u=(t-move['start'])/move['duration']
        return v+self.corrections[phase]/move['duration']*30*u*u*(1-u)**2

    def sample(self,t):
        """Return position, normalized travel and all three time derivatives."""
        t=max(self.start,min(self.stop,t));phase=0 if t<=self.moves[1]['start'] else 1;move=self.moves[phase]
        u=(t-move['start'])/move['duration']
        distance=(self.boundary if phase else 0)+self.raw_distance(move['start'],t)+self.corrections[phase]*(10*u**3-15*u**4+6*u**5)
        distance=max(0,min(self.length,distance));i=min(len(self.arc)-2,max(0,bisect.bisect_right(self.arc,distance)-1))
        q=(distance-self.arc[i])/max(.000000001,self.arc[i+1]-self.arc[i])
        parameter=self.parameters[i]+q*(self.parameters[i+1]-self.parameters[i])
        point=self.point(parameter);v=self.speed(t);direction=self.direction(parameter)
        return point+[distance/self.length]+[v*n for n in direction]+[v/self.length]


def source(scene,flight):
    """Emit data and a subframe Hermite sampler; appearance and clock live in the intro script."""
    count=round((flight.stop-flight.start)*HZ);rows=[flight.sample(flight.start+i/HZ) for i in range(count+1)]
    arrays=[]
    for axis in range(6):
        values=[f'{r[axis]:.10f}' for r in rows]
        arrays.append('[\n'+',\n'.join('        '+', '.join(values[i:i+8]) for i in range(0,len(values),8))+'\n    ]')
    return '''/// Samples selected V08 coordinates with continuous subframe position and velocity.
function funIntroFlightSample(frame, axis) {
    // Generated from tools/fixtures/startup-intro-v08.json; regenerate with tools/build_startup_intro.py.
    static positions = [ARRAYS]
    var sample = clamp((frame - START) * 4, 0, COUNT)
    var first = min(floor(sample), COUNT - 1)
    var u = sample - first
    var u2 = u * u
    var u3 = u2 * u
    var values = positions[axis]
    var velocities = positions[axis + 3]
    return (2*u3-3*u2+1)*values[first] + (u3-2*u2+u)*velocities[first]/240
        + (-2*u3+3*u2)*values[first+1] + (u3-u2)*velocities[first+1]/240
}

/// Supplies normalized distance for regression checks and the travelling trail.
function funIntroFlightProgress(frame) {
    return funIntroFlightSample(frame, 2)
}

/// Finds the letter crossing only during the selected return pass.
function funIntroFlightFrameAtX(px) {
    var low = RETURN
    var high = STOP
    repeat (24) {
        var mid = (low + high) * 0.5
        if (funIntroFlightSample(mid, 0) < px) low = mid
        else high = mid
    }
    return (low + high) * 0.5
}

/// Draws the selected short point trail and a rigid, smoothly translated light.
function funIntroFireflyDraw(frame, alpha, ink) {
    var previous_filter = gpu_get_texfilter()
    gpu_set_tex_filter(true)
    for (var i = 8; i >= 1; --i) {
        var delayed = frame - i * 2.1
        if (delayed < START or delayed >= STOP) continue
        var px = funIntroFlightSample(delayed, 0)
        var py = funIntroFlightSample(delayed, 1)
        var separation = point_distance(px, py, funIntroFlightSample(frame, 0), funIntroFlightSample(frame, 1))
        if (separation < 2) continue
        draw_set_color(ink)
        draw_set_alpha(alpha * 0.18 * (1 - i / 9))
        draw_rectangle(px, py, px + 1, py + 1, false)
    }
    funIntroSmoothGlow(funIntroFlightSample(frame, 0), funIntroFlightSample(frame, 1), alpha)
    gpu_set_tex_filter(previous_filter)
}
'''.replace('ARRAYS',',\n    '.join(arrays)).replace('START',f'{flight.start*60:.10f}').replace('COUNT',str(count)).replace('RETURN',f'{flight.moves[1]["start"]*60:.10f}').replace('STOP',f'{flight.stop*60:.10f}')


def main():
    """Regenerate only the selected motion script and print its join diagnostics."""
    scene=json.loads(SOURCE.read_text())['scene'];flight=Flight(scene)
    for i in range(10001):assert flight.speed(flight.start+(flight.stop-flight.start)*i/10000)>0
    TARGET.write_text(source(scene,flight))
    print(json.dumps({'phase_lengths':flight.lengths,'original_join_speeds':flight.original_join_speeds,'shared_join_speed':flight.speed(flight.moves[1]['start']),'distance_corrections':flight.corrections,'stop_seconds':flight.stop},indent=2))


if __name__=='__main__':main()
