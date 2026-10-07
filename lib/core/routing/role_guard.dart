class RoleGuard {
  const RoleGuard();
  bool canEnter({required String currentRole, required String requiredRole}) =>
      currentRole == requiredRole;
}
