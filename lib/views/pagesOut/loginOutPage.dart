import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendance/controlers/String.dart';
import 'package:tendance/landingPage/landingPage.dart' hide Colorsdata;
import 'package:tendance/views/pagesOut/forgotPasswordPage.dart';
import 'package:tendance/views/pagesOut/signupOutPage.dart';
import '../../controlers/ColorsData.dart';
import '../../controlers/authControler.dart';
import '../../utils/validators.dart';

class Loginoutpage extends StatefulWidget {
  const Loginoutpage({super.key});

  @override
  State<Loginoutpage> createState() => _LoginoutpageState();
}

class _LoginoutpageState extends State<Loginoutpage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _showPassword = false;
  String? _emailError;
  String? _passwordError;

  // 👇 On initialise le contrôleur GetX
  final AuthController _authController = Get.put(AuthController());
  final AuthController controller = Get.find();

  void _validateAndLogin() {
    setState(() {
      _emailError = combineValidators([
        Validator.isRequired,
        Validator.email,
      ])(_emailCtrl.text);

      _passwordError = Validator.isRequired(_passwordCtrl.text);
    });

    if (_emailError != null || _passwordError != null) return;

    // 👇 Appel du contrôleur pour la connexion
    _authController.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    double adaptiveSize(double small, double medium, double large) {
      if (width <= 500) return small;
      if (width <= 900) return medium;
      return large;
    }

    double maxContentWidth = adaptiveSize(width, 600, 450);

    return Scaffold(
      backgroundColor: Colorsdata().background,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if(!kIsWeb) SizedBox(height: 35,) else SizedBox(),
          // ─── FORMULAIRE ───────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Container(
                  width: width < 900 ? width : maxContentWidth,
                  padding: EdgeInsets.symmetric(
                    horizontal: adaptiveSize(15, 25, 30),
                    vertical: adaptiveSize(25, 30, 35),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // LOGO
                      Container(
                        padding: EdgeInsets.all(1.5),
                        height: adaptiveSize(55, 65, 70),
                        width: adaptiveSize(55, 65, 70),
                        margin: EdgeInsets.only(
                          top: adaptiveSize(40, 50, 60),
                          bottom: adaptiveSize(25, 30, 35),
                        ),
                        decoration: BoxDecoration(
                          color: Colorsdata().white,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: Colors.black),
                        ),
                        child: Center(
                          child: Image.asset(
                            "assets/icons/app_icon.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      Text(
                        "Se connecter",
                        style: TextStyle(
                          fontSize: adaptiveSize(22, 27, 30),
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextButton(onPressed: () {
                        Get.to(LandingPageTendance());
                      }, child: Text("Revenir à la page d'acceuil")),
                      Text(
                        "Accédez à votre compte Tendance",
                        style: TextStyle(
                          fontSize: adaptiveSize(13, 14, 15),
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: adaptiveSize(25, 30, 35)),

                      // FORMULAIRE
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: adaptiveSize(20, 30, 40),
                          vertical: adaptiveSize(20, 25, 30),
                        ),
                        decoration: BoxDecoration(
                          color: Colorsdata().white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Obx(() => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // EMAIL
                                const Text("Email",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: adaptiveSize(3, 5, 6)),
                                TextFormField(
                                  controller: _emailCtrl,
                                  onChanged: (_) =>
                                      setState(() => _emailError = null),
                                  decoration: InputDecoration(
                                    hintText: "Entrez votre email",
                                    prefixIcon: const Icon(
                                        Icons.email_outlined,
                                        color: Colors.grey),
                                    filled: true,
                                    fillColor: Colors.white,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(7),
                                      borderSide: BorderSide(
                                        color: _emailError == null
                                            ? Colors.grey
                                            : Colors.red,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(7),
                                      borderSide: BorderSide(
                                        width: 3,
                                        color: _emailError == null
                                            ? Colorsdata().buttonHover
                                            : Colors.red,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                  ),
                                ),
                                if (_emailError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 4, left: 5.0),
                                    child: Text(
                                      _emailError!,
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 12),
                                    ),
                                  ),

                                SizedBox(height: adaptiveSize(10, 12, 14)),

                                // MOT DE PASSE
                                const Text("Mot de passe",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: adaptiveSize(3, 5, 6)),
                                TextFormField(
                                  controller: _passwordCtrl,
                                  obscureText: !_showPassword,
                                  onChanged: (_) =>
                                      setState(() => _passwordError = null),
                                  decoration: InputDecoration(
                                    hintText: "Entrez votre mot de passe",
                                    prefixIcon: const Icon(Icons.lock_outline,
                                        color: Colors.grey),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _showPassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () => setState(
                                          () => _showPassword = !_showPassword),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(7),
                                      borderSide: BorderSide(
                                        color: _passwordError == null
                                            ? Colors.grey
                                            : Colors.red,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(7),
                                      borderSide: BorderSide(
                                        width: 3,
                                        color: _passwordError == null
                                            ? Colorsdata().buttonHover
                                            : Colors.red,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                  ),
                                ),
                                if (_passwordError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 4, left: 5.0),
                                    child: Text(
                                      _passwordError!,
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 12),
                                    ),
                                  ),
                                   Obx(() => 
                                   Text(
                                    controller.error.value, 
                                    style: TextStyle(fontSize: 11, color: Colors.red),)),
                                
                                
                                

                                SizedBox(height: adaptiveSize(10, 15, 20)),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        // On redirige vers la page ForgotPasswordPage
                                        // Ici isUserLogged = false car l'utilisateur n'est pas connecté sur la page login
                                        Get.to(() => ForgotPasswordPage(isUserLogged: false));
                                      },
                                      child: Text(
                                        "Mot de passe oublié ?",
                                        style: TextStyle(
                                          fontSize: adaptiveSize(10, 12, 12),
                                          color: Colorsdata().buttonHover,
                                        ),
                                      ),),
                                  ],
                                ),
                                SizedBox(height: adaptiveSize(5, 8, 10)),

                                // BOUTON DE CONNEXION
                                SizedBox(
                                  height: adaptiveSize(40, 42, 45),
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colorsdata().buttonHover,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(7)),
                                    ),
                                    onPressed: _authController.isLoading.value
                                        ? null
                                        : _validateAndLogin,
                                    icon: _authController.isLoading.value
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.login_outlined,
                                            color: Colors.white, size: 23),
                                    label: Text(
                                      _authController.isLoading.value
                                          ? "Connexion..."
                                          : "Se connecter",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: adaptiveSize(15, 17, 18),
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: adaptiveSize(12, 15, 18)),

                                Row(
                                  children: [
                                    Text("Vous n'avez pas encore de compte ?",
                                        style: TextStyle(
                                            fontSize:
                                                adaptiveSize(10, 14, 14))),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () {
                                        Get.to(() => const Signupoutpage());
                                      },
                                      child: Text(
                                        "Créer un compte",
                                        style: TextStyle(
                                            fontSize:
                                                adaptiveSize(12, 14, 14),
                                            color: Colorsdata().buttonHover),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
 