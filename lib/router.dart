import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wavemobileapp/routing_constants.dart';
import 'package:wavemobileapp/ui/views/authenticate_view.dart';
import 'package:wavemobileapp/ui/views/chatpage_view.dart';
import 'package:wavemobileapp/ui/views/home_view.dart';
import 'package:wavemobileapp/ui/views/onboarding_view.dart';
import 'package:wavemobileapp/ui/views/startup_view.dart';

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
    case OnboardingViewRoute:
      Map<String, String> arguments = settings.arguments as Map<String, String>;
      return MaterialPageRoute(
          builder: (context) =>
              OnboardingView(arguments['userUID'], arguments['phoneNUmber']));
    case ChatViewRoute:
      Map<String, String> arguments = settings.arguments as Map<String, String>;
      return MaterialPageRoute(
          builder: (context) =>
              ChatPageView(arguments['yourUID'], arguments['yourName']));
    default:
      return MaterialPageRoute(builder: (context) => StartupView());
  }
}
