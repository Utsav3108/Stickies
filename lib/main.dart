// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'services/storage_service.dart';
import 'providers/category_provider.dart';
import 'providers/entry_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/redesigned_home.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => EntryProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'Stickies',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.textChip,
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: Colors.black,
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _showAuth = false;
  bool _isAuthenticating = false;
  final LocalAuthentication _localAuth = LocalAuthentication();
  String _authStatus = '';

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();

    // Show auth screen after animation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showAuth = true;
        });
      }
    });

    // Check if biometric is available
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (mounted) {
        setState(() {
          if (canCheckBiometrics && isDeviceSupported) {
            _authStatus = 'Biometric available';
          } else if (isDeviceSupported) {
            _authStatus = 'Device PIN available';
          } else {
            _authStatus = 'No authentication available';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _authStatus = 'Error checking biometrics';
        });
      }
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    bool authenticated = false;

    try {
      // Check if device can authenticate
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!isDeviceSupported) {
        throw PlatformException(
          code: 'NotAvailable',
          message: 'Device does not support authentication',
        );
      }

      if (!canCheckBiometrics) {
        // Try device credentials (PIN/Pattern) if biometrics not available
        authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to access your stickies',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
            useErrorDialogs: true,
            sensitiveTransaction: false,
          ),
        );
      } else {
        // Try biometric authentication
        authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to access your stickies',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
            useErrorDialogs: true,
            sensitiveTransaction: false,
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        String message = 'Authentication error';

        switch (e.code) {
          case 'NotAvailable':
          case 'notAvailable':
            message = 'Authentication not available. Please set up a screen lock (PIN/Pattern/Fingerprint) in device settings.';
            break;
          case 'NotEnrolled':
          case 'PasscodeNotSet':
            message = 'No authentication method found. Please set up device lock in settings.';
            break;
          case 'LockedOut':
          case 'lockedOut':
            message = 'Too many attempts. Please try again later.';
            break;
          case 'PermanentlyLockedOut':
          case 'permanentlyLockedOut':
            message = 'Authentication locked. Please unlock your device and try again.';
            break;
          case 'OtherOperatingSystem':
            message = 'Biometric authentication not supported on this platform.';
            break;
          default:
            message = 'Authentication failed: ${e.message ?? e.code}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade900,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Skip',
              textColor: Colors.white,
              onPressed: () {
                // Skip authentication for development/testing
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 500),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: ${e.toString()}'),
            backgroundColor: Colors.red.shade900,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }

    if (authenticated && mounted) {
      // Show success feedback
      HapticFeedback.mediumImpact();

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated background gradient circles
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value * 0.3,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.photoChip.withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value * 0.3,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.textChip.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Main content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    // Animated logo
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: _buildLogoStack(),
                    ),
                    const SizedBox(height: 40),
                    // App name
                    AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: child,
                        );
                      },
                      child: const Text(
                        'Stickies',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Tagline
                    AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value * 0.7,
                          child: child,
                        );
                      },
                      child: const Text(
                        'Your thoughts, organized',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white54,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Auth button
                    if (_showAuth)
                      AnimatedOpacity(
                        opacity: _showAuth ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 600),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _isAuthenticating ? null : _authenticate,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 48,
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _isAuthenticating
                                        ? [
                                      AppColors.saveButton.withOpacity(0.5),
                                      AppColors.saveButton.withOpacity(0.3),
                                    ]
                                        : [
                                      AppColors.saveButton,
                                      AppColors.saveButton.withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.saveButton.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isAuthenticating)
                                      const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.black87,
                                          ),
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.fingerprint,
                                        color: Colors.black87,
                                        size: 28,
                                      ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _isAuthenticating ? 'Authenticating...' : 'Get Started',
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isAuthenticating
                                  ? 'Please authenticate...'
                                  : 'Tap to unlock',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoStack() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background sticky notes with rotation
        Transform.rotate(
          angle: -0.15,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.videoChip.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(-5, 10),
                ),
              ],
            ),
          ),
        ),
        Transform.rotate(
          angle: 0.1,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.textChip.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
          ),
        ),
        // Front sticky note
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.photoChip,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 25,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.sticky_note_2_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}




// // lib/main.dart
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import 'package:local_auth/local_auth.dart';
// import 'services/storage_service.dart';
// import 'providers/category_provider.dart';
// import 'providers/entry_provider.dart';
// import 'providers/settings_provider.dart';
// import 'screens/redesigned_home.dart';
// import 'theme/app_colors.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await StorageService.init();
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => CategoryProvider()),
//         ChangeNotifierProvider(create: (_) => EntryProvider()),
//         ChangeNotifierProvider(create: (_) => SettingsProvider()),
//       ],
//       child: MaterialApp(
//         title: 'Stickies',
//         debugShowCheckedModeBanner: false,
//         theme: ThemeData(
//           colorScheme: ColorScheme.fromSeed(
//             seedColor: AppColors.textChip,
//             brightness: Brightness.dark,
//           ),
//           scaffoldBackgroundColor: Colors.black,
//           useMaterial3: true,
//         ),
//         home: const SplashScreen(),
//       ),
//     );
//   }
// }
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   late Animation<double> _scaleAnimation;
//   bool _showAuth = false;
//   bool _isAuthenticating = false;
//   final LocalAuthentication _localAuth = LocalAuthentication();
//   String _authStatus = '';
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//
//
//   @override
//   void initState() {
//     super.initState();
//
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1500),
//     );
//
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
//       ),
//     );
//
//     _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
//       ),
//     );
//
//     _animationController.forward();
//
//     // Show auth screen after animation
//     Future.delayed(const Duration(milliseconds: 800), () {
//       if (mounted) {
//         setState(() {
//           _showAuth = true;
//         });
//       }
//     });
//
//     // Check if biometric is available
//     _checkBiometrics();
//   }
//
//   Future<void> _checkBiometrics() async {
//     try {
//       final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
//       final bool isDeviceSupported = await _localAuth.isDeviceSupported();
//
//       if (mounted) {
//         setState(() {
//           if (canCheckBiometrics && isDeviceSupported) {
//             _authStatus = 'Biometric available';
//           } else if (isDeviceSupported) {
//             _authStatus = 'Device PIN available';
//           } else {
//             _authStatus = 'No authentication available';
//           }
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _authStatus = 'Error checking biometrics';
//         });
//       }
//     }
//   }
//
//   Future<void> _authenticate() async {
//     if (_isAuthenticating) return;
//
//     setState(() {
//       _isAuthenticating = true;
//     });
//
//     bool authenticated = false;
//
//     try {
//       authenticated = await _localAuth.authenticate(
//         localizedReason: 'Authenticate to access your stickies',
//         options: const AuthenticationOptions(
//           stickyAuth: true,
//           biometricOnly: true, // Allow PIN/Pattern as fallback
//         ),
//       );
//     } on PlatformException catch (e) {
//       if (mounted) {
//         String message = 'Authentication error';
//         if (e.code == 'NotAvailable') {
//           message = 'Biometric authentication not available';
//         } else if (e.code == 'NotEnrolled') {
//           message = 'No biometrics enrolled';
//         } else if (e.code == 'LockedOut') {
//           message = 'Too many attempts. Please try again later';
//         } else if (e.code == 'PermanentlyLockedOut') {
//           message = 'Authentication permanently locked';
//         }
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(message),
//             backgroundColor: Colors.red.shade900,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: ${e.toString()}'),
//             backgroundColor: Colors.red.shade900,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isAuthenticating = false;
//         });
//       }
//     }
//
//     if (authenticated && mounted) {
//       // Show success feedback
//       HapticFeedback.mediumImpact();
//
//       Navigator.of(context).pushReplacement(
//         PageRouteBuilder(
//           pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
//           transitionsBuilder: (context, animation, secondaryAnimation, child) {
//             return FadeTransition(opacity: animation, child: child);
//           },
//           transitionDuration: const Duration(milliseconds: 500),
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           // Animated background gradient circles
//           Positioned(
//             top: -100,
//             right: -100,
//             child: AnimatedBuilder(
//               animation: _animationController,
//               builder: (context, child) {
//                 return Opacity(
//                   opacity: _fadeAnimation.value * 0.3,
//                   child: Container(
//                     width: 300,
//                     height: 300,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       gradient: RadialGradient(
//                         colors: [
//                           AppColors.photoChip.withOpacity(0.4),
//                           Colors.transparent,
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           Positioned(
//             bottom: -150,
//             left: -150,
//             child: AnimatedBuilder(
//               animation: _animationController,
//               builder: (context, child) {
//                 return Opacity(
//                   opacity: _fadeAnimation.value * 0.3,
//                   child: Container(
//                     width: 400,
//                     height: 400,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       gradient: RadialGradient(
//                         colors: [
//                           AppColors.textChip.withOpacity(0.3),
//                           Colors.transparent,
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           // Main content
//           SafeArea(
//             child: Center(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 40),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Spacer(),
//                     // Animated logo
//                     AnimatedBuilder(
//                       animation: _animationController,
//                       builder: (context, child) {
//                         return Transform.scale(
//                           scale: _scaleAnimation.value,
//                           child: Opacity(
//                             opacity: _fadeAnimation.value,
//                             child: child,
//                           ),
//                         );
//                       },
//                       child: _buildLogoStack(),
//                     ),
//                     const SizedBox(height: 40),
//                     // App name
//                     AnimatedBuilder(
//                       animation: _fadeAnimation,
//                       builder: (context, child) {
//                         return Opacity(
//                           opacity: _fadeAnimation.value,
//                           child: child,
//                         );
//                       },
//                       child: const Text(
//                         'Stickies',
//                         style: TextStyle(
//                           fontSize: 56,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                           letterSpacing: -1,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     // Tagline
//                     AnimatedBuilder(
//                       animation: _fadeAnimation,
//                       builder: (context, child) {
//                         return Opacity(
//                           opacity: _fadeAnimation.value * 0.7,
//                           child: child,
//                         );
//                       },
//                       child: const Text(
//                         'Your thoughts, organized',
//                         style: TextStyle(
//                           fontSize: 18,
//                           color: Colors.white54,
//                           letterSpacing: 0.5,
//                         ),
//                       ),
//                     ),
//                     const Spacer(),
//                     // Auth button
//                     if (_showAuth)
//                       AnimatedOpacity(
//                         opacity: _showAuth ? 1.0 : 0.0,
//                         duration: const Duration(milliseconds: 600),
//                         child: Column(
//                           children: [
//                             GestureDetector(
//                               onTap: _isAuthenticating ? null : _authenticate,
//                               child: AnimatedContainer(
//                                 duration: const Duration(milliseconds: 200),
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 48,
//                                   vertical: 18,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   gradient: LinearGradient(
//                                     colors: _isAuthenticating
//                                         ? [
//                                       AppColors.saveButton.withOpacity(0.5),
//                                       AppColors.saveButton.withOpacity(0.3),
//                                     ]
//                                         : [
//                                       AppColors.saveButton,
//                                       AppColors.saveButton.withOpacity(0.8),
//                                     ],
//                                   ),
//                                   borderRadius: BorderRadius.circular(30),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: AppColors.saveButton.withOpacity(0.3),
//                                       blurRadius: 20,
//                                       offset: const Offset(0, 10),
//                                     ),
//                                   ],
//                                 ),
//                                 child: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     if (_isAuthenticating)
//                                       const SizedBox(
//                                         width: 24,
//                                         height: 24,
//                                         child: CircularProgressIndicator(
//                                           strokeWidth: 2.5,
//                                           valueColor: AlwaysStoppedAnimation<Color>(
//                                             Colors.black87,
//                                           ),
//                                         ),
//                                       )
//                                     else
//                                       const Icon(
//                                         Icons.fingerprint,
//                                         color: Colors.black87,
//                                         size: 28,
//                                       ),
//                                     const SizedBox(width: 12),
//                                     Text(
//                                       _isAuthenticating ? 'Authenticating...' : 'Get Started',
//                                       style: const TextStyle(
//                                         color: Colors.black87,
//                                         fontSize: 18,
//                                         fontWeight: FontWeight.bold,
//                                         letterSpacing: 0.5,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 16),
//                             Text(
//                               _isAuthenticating
//                                   ? 'Please authenticate...'
//                                   : 'Tap to unlock',
//                               style: TextStyle(
//                                 color: Colors.white.withOpacity(0.4),
//                                 fontSize: 14,
//                                 letterSpacing: 0.5,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     const SizedBox(height: 60),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildLogoStack() {
//     return Stack(
//       alignment: Alignment.center,
//       children: [
//         // Background sticky notes with rotation
//         Transform.rotate(
//           angle: -0.15,
//           child: Container(
//             width: 120,
//             height: 120,
//             decoration: BoxDecoration(
//               color: AppColors.videoChip.withOpacity(0.8),
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.3),
//                   blurRadius: 20,
//                   offset: const Offset(-5, 10),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         Transform.rotate(
//           angle: 0.1,
//           child: Container(
//             width: 120,
//             height: 120,
//             decoration: BoxDecoration(
//               color: AppColors.textChip.withOpacity(0.9),
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.3),
//                   blurRadius: 20,
//                   offset: const Offset(0, 5),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         // Front sticky note
//         Container(
//           width: 120,
//           height: 120,
//           decoration: BoxDecoration(
//             color: AppColors.photoChip,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.4),
//                 blurRadius: 25,
//                 offset: const Offset(0, 15),
//               ),
//             ],
//           ),
//           child: const Center(
//             child: Icon(
//               Icons.sticky_note_2_rounded,
//               size: 60,
//               color: Colors.white,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }



// // lib/main.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'services/storage_service.dart';
// import 'providers/category_provider.dart';
// import 'providers/entry_provider.dart';
// import 'providers/settings_provider.dart';
// import 'screens/redesigned_home.dart';
// import 'theme/app_colors.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await StorageService.init();
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => CategoryProvider()),
//         ChangeNotifierProvider(create: (_) => EntryProvider()),
//         ChangeNotifierProvider(create: (_) => SettingsProvider()),
//       ],
//       child: MaterialApp(
//         title: 'Stickies',
//         debugShowCheckedModeBanner: false,
//         theme: ThemeData(
//           colorScheme: ColorScheme.fromSeed(
//             seedColor: AppColors.textChip,
//             brightness: Brightness.dark,
//           ),
//           scaffoldBackgroundColor: Colors.black,
//           useMaterial3: true,
//         ),
//         home: const SplashScreen(),
//       ),
//     );
//   }
// }
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   late Animation<double> _scaleAnimation;
//   bool _showAuth = false;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1500),
//     );
//
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
//       ),
//     );
//
//     _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
//       ),
//     );
//
//     _animationController.forward();
//
//     // Show auth screen after animation
//     Future.delayed(const Duration(milliseconds: 800), () {
//       if (mounted) {
//         setState(() {
//           _showAuth = true;
//         });
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   void _authenticate() {
//     Navigator.of(context).pushReplacement(
//       PageRouteBuilder(
//         pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
//         transitionsBuilder: (context, animation, secondaryAnimation, child) {
//           return FadeTransition(opacity: animation, child: child);
//         },
//         transitionDuration: const Duration(milliseconds: 500),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           // Animated background gradient circles
//           Positioned(
//             top: -100,
//             right: -100,
//             child: AnimatedBuilder(
//               animation: _animationController,
//               builder: (context, child) {
//                 return Opacity(
//                   opacity: _fadeAnimation.value * 0.3,
//                   child: Container(
//                     width: 300,
//                     height: 300,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       gradient: RadialGradient(
//                         colors: [
//                           AppColors.photoChip.withOpacity(0.4),
//                           Colors.transparent,
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           Positioned(
//             bottom: -150,
//             left: -150,
//             child: AnimatedBuilder(
//               animation: _animationController,
//               builder: (context, child) {
//                 return Opacity(
//                   opacity: _fadeAnimation.value * 0.3,
//                   child: Container(
//                     width: 400,
//                     height: 400,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       gradient: RadialGradient(
//                         colors: [
//                           AppColors.textChip.withOpacity(0.3),
//                           Colors.transparent,
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           // Main content
//           SafeArea(
//             child: Center(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 40),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Spacer(),
//                     // Animated logo
//                     AnimatedBuilder(
//                       animation: _animationController,
//                       builder: (context, child) {
//                         return Transform.scale(
//                           scale: _scaleAnimation.value,
//                           child: Opacity(
//                             opacity: _fadeAnimation.value,
//                             child: child,
//                           ),
//                         );
//                       },
//                       child: _buildLogoStack(),
//                     ),
//                     const SizedBox(height: 40),
//                     // App name
//                     AnimatedBuilder(
//                       animation: _fadeAnimation,
//                       builder: (context, child) {
//                         return Opacity(
//                           opacity: _fadeAnimation.value,
//                           child: child,
//                         );
//                       },
//                       child: const Text(
//                         'Stickies',
//                         style: TextStyle(
//                           fontSize: 56,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                           letterSpacing: -1,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     // Tagline
//                     AnimatedBuilder(
//                       animation: _fadeAnimation,
//                       builder: (context, child) {
//                         return Opacity(
//                           opacity: _fadeAnimation.value * 0.7,
//                           child: child,
//                         );
//                       },
//                       child: const Text(
//                         'Your thoughts, organized',
//                         style: TextStyle(
//                           fontSize: 18,
//                           color: Colors.white54,
//                           letterSpacing: 0.5,
//                         ),
//                       ),
//                     ),
//                     const Spacer(),
//                     // Auth button
//                     if (_showAuth)
//                       AnimatedOpacity(
//                         opacity: _showAuth ? 1.0 : 0.0,
//                         duration: const Duration(milliseconds: 600),
//                         child: Column(
//                           children: [
//                             GestureDetector(
//                               onTap: _authenticate,
//                               child: Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 48,
//                                   vertical: 18,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   gradient: LinearGradient(
//                                     colors: [
//                                       AppColors.saveButton,
//                                       AppColors.saveButton.withOpacity(0.8),
//                                     ],
//                                   ),
//                                   borderRadius: BorderRadius.circular(30),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: AppColors.saveButton.withOpacity(0.3),
//                                       blurRadius: 20,
//                                       offset: const Offset(0, 10),
//                                     ),
//                                   ],
//                                 ),
//                                 child: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: const [
//                                     Icon(
//                                       Icons.fingerprint,
//                                       color: Colors.black87,
//                                       size: 28,
//                                     ),
//                                     SizedBox(width: 12),
//                                     Text(
//                                       'Get Started',
//                                       style: TextStyle(
//                                         color: Colors.black87,
//                                         fontSize: 18,
//                                         fontWeight: FontWeight.bold,
//                                         letterSpacing: 0.5,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 16),
//                             Text(
//                               'Tap to unlock',
//                               style: TextStyle(
//                                 color: Colors.white.withOpacity(0.4),
//                                 fontSize: 14,
//                                 letterSpacing: 0.5,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     const SizedBox(height: 60),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildLogoStack() {
//     return Stack(
//       alignment: Alignment.center,
//       children: [
//         // Background sticky notes with rotation
//         Transform.rotate(
//           angle: -0.15,
//           child: Container(
//             width: 120,
//             height: 120,
//             decoration: BoxDecoration(
//               color: AppColors.videoChip.withOpacity(0.8),
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.3),
//                   blurRadius: 20,
//                   offset: const Offset(-5, 10),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         Transform.rotate(
//           angle: 0.1,
//           child: Container(
//             width: 120,
//             height: 120,
//             decoration: BoxDecoration(
//               color: AppColors.textChip.withOpacity(0.9),
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.3),
//                   blurRadius: 20,
//                   offset: const Offset(0, 5),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         // Front sticky note
//         Container(
//           width: 120,
//           height: 120,
//           decoration: BoxDecoration(
//             color: AppColors.photoChip,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.4),
//                 blurRadius: 25,
//                 offset: const Offset(0, 15),
//               ),
//             ],
//           ),
//           child: const Center(
//             child: Icon(
//               Icons.sticky_note_2_rounded,
//               size: 60,
//               color: Colors.white,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }