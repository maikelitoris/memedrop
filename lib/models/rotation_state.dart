class RotationState {
  final double pitchDeg; // X-axis rotation (tumble forward/back)
  final double yawDeg;   // Y-axis rotation (spin left/right)
  const RotationState({this.pitchDeg = 0.0, this.yawDeg = 0.0});
}
