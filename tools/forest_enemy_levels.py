"""Author spaced encounter lanes for the requested evening and new night test levels."""
import json,shutil
from theme_assets import ROOT,PROJECT,read_resource,write_resource,append_entries


def lane(width,height,floor):
    """Create an open forest route with an empty camera border and solid lower terrain."""
    grid=[['.']*width for _ in range(height)]
    for y in range(floor,height-1):
        for x in range(1,width-1):grid[y][x]='#'
    return grid


def rock(grid,left,right,top,bottom):
    """Place a rectangular mound whose sides provide alternative jumping routes."""
    for y in range(top,bottom):
        for x in range(left,right):grid[y][x]='#'


def entity(grid,x,y,symbol):
    """Place an enemy or pickup only into an open cell."""
    assert grid[y][x]=='.',(x,y,symbol);grid[y][x]=symbol


def save(number,grid,title,stars):
    """Write one editable semantic level while preserving the previous evening level as an archive."""
    path=PROJECT/f'datafiles/challenge_levels/{number:02d}.json';backup=ROOT/'.temp/enemy_integration/previous-level-22.json'
    if number==12 and not backup.exists():shutil.copyfile(path,backup)
    write_resource(path,{'width':len(grid[0]),'height':len(grid),'style':{'profile':'forest','seed':20261014+number,'grass_chance':.35},'star_times':{'three_stars':stars,'two_stars':stars*2},'map':[''.join(row) for row in grid],'test_encounters':title})


def main():
    """Install level 22 for all evening/day/morning skins and append level 32 for the six night behaviours."""
    g=lane(187,32,27);entity(g,7,26,'@');entity(g,179,25,'O')
    for x,symbol in [(24,'K'),(50,'5'),(77,'1'),(104,'2'),(132,'4'),(159,'7')]:entity(g,x,26,symbol)
    for x in [15,38,65,92,120,146,172]:entity(g,x,24,'*')
    for x in [34,61,88,116,144,171]:rock(g,x,x+2,25,27)
    save(12,g,'22: Suchnik, resin evening, guard day, guard evening, guard morning, resin morning',90)
    g=lane(214,34,28);entity(g,7,27,'@');entity(g,205,26,'O')
    for x,y,symbol in [(29,27,'J'),(63,27,'F'),(95,24,'C'),(126,21,'T'),(158,27,'G'),(191,27,'W')]:entity(g,x,y,symbol)
    rock(g,121,132,16,17)  # A real underside for the bat's first wake/drop.
    rock(g,87,100,25,28)
    for x in [42,75,111,143,176]:rock(g,x,x+2,26,28)
    rock(g,53,55,24,28)
    for x in range(55,60):g[24][x]='='
    for x in [17,46,71,82,105,136,169,200]:entity(g,x,23,'*')
    save(22,g,'32: resin jump, root maw bypass, bomber ridge, bat dive, guardian, reaper counterattack',100)
    catalog=read_resource(PROJECT/'datafiles/challenge_levels/catalog.json');path='challenge_levels/22.json'
    if path not in catalog['levels']:catalog['levels'].append(path)
    write_resource(PROJECT/'datafiles/challenge_levels/catalog.json',catalog)
    project=read_resource(PROJECT/'RandomForest.yyp')
    if not any(f['name']=='22.json' and f['filePath']=='datafiles/challenge_levels' for f in project['IncludedFiles']):
        append_entries(PROJECT/'RandomForest.yyp','IncludedFiles',[{'$GMIncludedFile':'','%Name':'22.json','CopyToMask':-1,'filePath':'datafiles/challenge_levels','name':'22.json','resourceType':'GMIncludedFile','resourceVersion':'2.0'}])
    print('Prepared campaign levels 22 and 32; encounters separated by at least 26 cells')


if __name__=='__main__':main()
