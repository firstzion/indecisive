import Foundation

/// A fast, seedable, **non**-cryptographic RNG (SplitMix64) used only in
/// tests, so `PickService.choose` can be driven with a reproducible sequence
/// instead of `SystemRandomNumberGenerator`. Production code always uses the
/// system generator for real randomness.
///
/// Lives in the test target (not `Indecisive/Logic`, where it used to sit) —
/// only `PickServiceLogicTests` ever references it, so it has no business
/// shipping inside the app binary.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
