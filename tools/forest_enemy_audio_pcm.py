"""Preserve low-level recorded releases in standard little-endian PCM WAV files."""
import wave

import numpy as np


def read_pcm(path):
    """Decode signed 16- or 24-bit WAV into normalized samples without reducing its precision."""
    with wave.open(str(path),'rb') as wav:
        params = wav.getparams()
        raw = wav.readframes(params.nframes)
    if params.sampwidth==2:
        values = np.frombuffer(raw,dtype='<i2').astype(np.int32)
    elif params.sampwidth==3:
        octets = np.frombuffer(raw,dtype=np.uint8).reshape(-1,3).astype(np.int32)
        values = octets[:,0] | (octets[:,1]<<8) | (octets[:,2]<<16)
        values = (values ^ 0x800000)-0x800000
    else:
        raise ValueError(f'Unsupported PCM width: {params.sampwidth}')
    samples = values.astype(float)/(1<<(params.sampwidth*8-1))
    return samples.reshape(-1,params.nchannels),params


def encode_pcm(samples,bits):
    """Quantize once at the requested precision, retaining quiet tails instead of truncating to 16 bits."""
    values = np.rint(samples*(1<<(bits-1))).astype(np.int32)
    if bits==16:
        return values.astype('<i2').tobytes()
    if bits==24:
        flat = values.reshape(-1)
        return np.column_stack([flat&255,(flat>>8)&255,(flat>>16)&255]).astype(np.uint8).tobytes()
    raise ValueError(f'Unsupported PCM bits: {bits}')
