enum NamedRoutes {
  root('/'),
  login('/login'),
  activation('/activation');

  final String routeName;

  const NamedRoutes(this.routeName);
}
