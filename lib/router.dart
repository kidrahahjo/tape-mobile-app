import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tapemobileapp/routing_constants.dart';
import 'package:tapemobileapp/ui/views/authenticate_view.dart';
import 'package:tapemobileapp/ui/views/chatpage_view.dart';
import 'package:tapemobileapp/ui/views/home_view.dart';
import 'package:tapemobileapp/ui/views/onboarding_view.dart';
import 'package:tapemobileapp/ui/views/profile_view.dart';
import 'package:tapemobileapp/ui/views/startup_view.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case StartupViewRoute:
      return MaterialPageRoute(builder: (context) => StartupView());
    case AuthenticationViewRoute:
      return MaterialPageRoute(builder: (context) => AuthenticationView());
    case HomeViewRoute:
      Map<String, String> arguments = settings.arguments as Map<String, String>;
      return MaterialPageRoute(
          builder: (context) =>
              HomeView(arguments['userUID'], arguments['phoneNumber']));
    case ProfileViewRoute:
      Map<String, String> arguments = settings.arguments as Map<String, String>;
      return MaterialPageRoute(
          builder: (context) =>
              ProfileView(arguments['downloadURL'], arguments['displayName']));
    case OnboardingViewRoute:
      Map<String, String> arguments = settings.arguments as Map<String, String>;
      return MaterialPageRoute(
          builder: (context) =>
              OnboardingView(arguments['userUID'], arguments['phoneNumber']));
    case ChatViewRoute:
      Map<String, String> arguments = settings.arguments as Map<String, String>;
      return MaterialPageRoute(
          builder: (context) =>
              ChatPageView(arguments['yourUID'], arguments['yourName']));
    default:
      return MaterialPageRoute(builder: (context) => StartupView());
  }
}
