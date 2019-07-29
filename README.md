# Curve13318 research

Implementation of Barreto's curve "Curve13318" for Sandy Bridge and Ivy Bridge.
This implementation emulates 53-bit integers, uses IB's `ymm` bank to compute
4-way parallel arithmetic in GF(25519).

## Dependencies

- `make`
- `nasm`
- `gcc` (`clang` is not supported)

## Benchmarking instructions

- First, to get reliable benchmarking results, set up your target:
    - Disable TurboBoost
    - Disable all the HyperThreading cores
    - Set the CPU scaling to 'performance'
- Then, run (on an idle machine): `make bench`

