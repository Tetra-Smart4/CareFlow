class AuthGuard {
  const AuthGuard();
  bool canEnter({required bool authenticated}) => authenticated;
}
