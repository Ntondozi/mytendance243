import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendance/views/pagesOut/loginOutPage.dart';
import '../../controlers/authControler.dart';
import '../../controlers/ColorsData.dart';
import '../../utils/validators.dart';

class Signupoutpage extends StatefulWidget {
  const Signupoutpage({super.key});

  @override
  State<Signupoutpage> createState() => _SignupoutpageState();

}

class _SignupoutpageState extends State<Signupoutpage> {
  final AuthController controller = Get.find<AuthController>();
  
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final villeController = TextEditingController();
  final bioController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final villeAutreController = TextEditingController();



  String? selectedValue;
  final List<String> compte = ['Acheteur', 'Vendeur', 'Mixte'];

  String? selectedVille;
  final List<String> villes = ['Kinshasa', 'Lubumbashi', 'Goma', 'Autre'];
  bool showAutreVilleField = false;

  // États d'erreur
  Map<String, String?> errors = {};

  bool showPassword = false;
  bool showConfirmPassword = false;

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    villeController.dispose();
    bioController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    villeAutreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    double adaptive(double mobile, double tablet, double desktop) {
      if (width <= 500) return mobile;
      if (width <= 1000) return tablet;
      return desktop;
    }

    final formWidth = adaptive(width * 0.9, width * 0.7, width * 0.45);
    final fontSizeTitle = adaptive(22, 24, 26);
    final fontSizeButton = adaptive(13, 15, 16);
    final labelFontSize = adaptive(14, 15, 16);
    final hintFontSize = adaptive(13, 14, 15);
    
    final iconSize = adaptive(50, 55, 60);
    final buttonHeight = adaptive(45, 48, 52);

    return Scaffold(
      backgroundColor: Colorsdata().background,
      body: Center(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const CircularProgressIndicator();
          }
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Column(
                children: [
                  
                  SizedBox(height: height / 20),
                  Container(
                    padding: EdgeInsets.all(adaptive(12, 16, 20)),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.person_add_alt_1_outlined,
                      size: iconSize,
                      color: Colorsdata().white,
                    ),
                  ),
                  SizedBox(height: height / 50),
                  Text(
                    "Créer votre compte",
                    style: TextStyle(
                      fontSize: fontSizeTitle,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: height / 60),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Ou ', style: TextStyle(fontSize: adaptive(14, 15, 16))),
                      TextButton(onPressed: () => Get.to(Loginoutpage()), child: Text(
                        "connectez-vous à votre compte existant",
                        style: TextStyle(
                          fontSize: adaptive(14, 15, 16),
                          fontWeight: FontWeight.bold,
                          color: Colorsdata().buttonHover,
                        ),
                      ),)
                    ],
                  ),
                  SizedBox(height: height / 20),

                  // FORMULAIRE
                  Container(
                    width: formWidth,
                    padding: EdgeInsets.all(adaptive(15, 20, 25)),
                    margin: EdgeInsets.only(bottom: height / 25),
                    decoration: BoxDecoration(
                      color: Colorsdata().white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.4),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildLabel("Nom d'utilisateur *", labelFontSize),
                        buildTextField(usernameController,
                            fieldName: 'username',
                            hintText: "Entrez votre nom d'utilisateur",
                            hintFontSize: hintFontSize,
                            prefixIcon: Icons.person),
                        buildError('username'),

                        SizedBox(height: 8,),
                        buildLabel("Email *", labelFontSize),
                        buildTextField(emailController,
                            fieldName: 'email',
                            hintText: "Entrez votre email",
                            hintFontSize: hintFontSize,
                            prefixIcon: Icons.email),
                        buildError('email'),

                        SizedBox(height: 8,),
                        buildLabel('Rôle principal', labelFontSize),
                        buildDropdown(width, height),
                        SizedBox(height: height / 100),
                        Text(
                          "Votre choix n'aura aucune incidence sur vos fonctionnalités dans l'application. Vous pouvez achetez et vendre librement ",
                          style: TextStyle(fontSize: adaptive(11.5, 13, 14),),
                          textAlign: TextAlign.justify,
                        ),
                        SizedBox(height: height / 80),

                        buildLabel("Téléphone *", labelFontSize),
                        buildTextField(phoneController,

                            fieldName: 'phone',
                            hintText: "997283683",
                            hintFontSize: 16,
                            
                            prefix: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.phone),
                                SizedBox(width: 4),
                                Text('+243', style: TextStyle(fontSize: 16 ,color: Color.fromARGB(255, 27, 27, 27))),
                               ],
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 9),
                        buildError('phone'),

                        SizedBox(height: 8,),
                        buildLabel("Ville *", labelFontSize),
                        DropdownButtonFormField<String>(
                          value: selectedVille,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  width: 2, color: Colorsdata().buttonHover),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          hint: const Text("Sélectionner votre ville"),
                          items: villes.map((ville) {
                            return DropdownMenuItem(
                              value: ville,
                              child: Text(ville),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedVille = val;
                              showAutreVilleField = val == 'Autre';
                              errors.remove('ville');
                            });
                          },
                        ),
                        buildError('ville'),

                        SizedBox(height: 8,),
                        if (showAutreVilleField)
                          buildTextField(villeAutreController,
                              fieldName: 'autre Ville',
                              hintFontSize: hintFontSize,
                              hintText: "Entrez votre ville"),
                        if (showAutreVilleField) buildError('autreVille'),
                        SizedBox(height: 8,),

                        buildLabel("Biographie", labelFontSize),
                        buildTextField(bioController,
                            fieldName: 'bio',
                            hintText: "Parlez un peu de vous... Cette information nous permet de mieux vous mettre en valeur auprès des acheteurs et vendeurs potentiels. Elle aide à creer un climat de confiance et à faciliter les echanges",
                            hintFontSize: hintFontSize,
                            maxLines: 5),
                        SizedBox(height: height / 80),

                        buildLabel("Mot de passe *", labelFontSize),
                        buildTextField(passwordController,
                            fieldName: 'password',
                            hintText: "Entrez votre mot de passe",
                            hintFontSize: hintFontSize,
                            prefixIcon: Icons.lock,
                            obscure: !showPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                  showPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey),
                              onPressed: () {
                                setState(() => showPassword = !showPassword);
                              },
                            )),
                        buildError('password'),
                        
                        SizedBox(height: 8,),
                        buildLabel("Confirmer le mot de passe *", labelFontSize),
                        buildTextField(confirmPasswordController,
                            fieldName: 'confirmPassword',
                            hintText: "Confirmez votre mot de passe",
                            hintFontSize: hintFontSize,
                            prefixIcon: Icons.lock,
                            obscure: !showConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                  showConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey),
                              onPressed: () {
                                setState(() => showConfirmPassword = !showConfirmPassword);
                              },
                            )),
                        buildError('confirmPassword'),

                        SizedBox(height: height / 60),


                        Obx(() => 
                                   Text(
                                    controller.error.value, 
                                    style: TextStyle(fontSize: 11, color: Colors.red),)),
                                  

                        SizedBox(height: height / 40),

                        // BOUTON
                        SizedBox(
                          height: buttonHeight,
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colorsdata().buttonHover,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: validateForm,
                            icon: Icon(Icons.person_add_alt_outlined,
                                color: Colors.white, size: adaptive(20, 22, 24)),
                            label: Text(
                              "Créer un compte",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: adaptive(14, 15, 16),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: height / 40),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: adaptive(8, 10, 15)),
                          child: Text(
                            "En créant un compte, vous acceptez nos conditions d'utilisation et notre politique de confidentialité.",
                            style: TextStyle(fontSize: adaptive(12, 13, 14)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget buildLabel(String text, double fontSize) => Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
      );

  Widget buildTextField(TextEditingController controller,
      {required String fieldName,
      bool obscure = false,
      int? maxLength,
      int maxLines = 1,
      double? hintFontSize,
      IconData? prefixIcon,
      Widget? prefix,
      Widget? suffixIcon,
      String? hintText,
      TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      maxLength: maxLength,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() => errors.remove(fieldName)),
      decoration: InputDecoration(
        counterText: "",
        filled: true,
        fillColor: Colors.white,
        hintText: hintText ?? '',
        hintStyle: TextStyle(color: Colors.grey, fontSize: hintFontSize,),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        prefixIcon: prefix != null
        ? Padding(
            padding: const EdgeInsets.only(left: 10,),
            child: prefix,
          )
        : (prefixIcon != null
        ? Padding(
            padding: const EdgeInsets.only(left: 10, right: 6),
            child: Icon(prefixIcon),
          )
        : null),

        
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: errors[fieldName] != null ? Colors.red : Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              width: 2,
              color: errors[fieldName] != null
                  ? Colors.red
                  : Colorsdata().buttonHover),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget buildError(String fieldName) {
    if (errors[fieldName] == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 4),
      child: Text(
        errors[fieldName]!,
        style: const TextStyle(color: Colors.red, fontSize: 13),
      ),
    );
  }

  void validateForm() async {
    final usernameError = Validator.isRequired(usernameController.text);
    final emailError = Validator.email(emailController.text);
    final phoneError = Validator.phone(phoneController.text);
    final passwordError = Validator.password(passwordController.text);

    final confirmPasswordError =
        Validator.equalsTo(passwordController)(confirmPasswordController.text);
    final villeError = Validator.villeRequired(
        showAutreVilleField ? villeAutreController.text : selectedVille,
        showAutreVilleField);

    setState(() {
      errors = {
        'username': usernameError,
        'email': emailError,
        'phone': phoneError,
        'password': passwordError,
        'confirmPassword': confirmPasswordError,
        'ville': villeError,
      };

      if (showAutreVilleField) {
        errors['autreVille'] = villeError;
      }
    });

    if (errors.values.any((e) => e != null)) return;

    final phoneWithPrefix = '+243${phoneController.text.trim()}';

    await controller.signUp(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      username: usernameController.text.trim(),
      typeCompte: selectedValue ?? '',
      phone: phoneWithPrefix,
      ville: showAutreVilleField
          ? villeAutreController.text.trim()
          : (selectedVille ?? ''),
      bio: bioController.text.trim(),
    );
  }

  Widget buildDropdown(double width, double height) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: height / 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colorsdata().background,
        border: Border.all(color: Colors.grey),
      ),
      child: DropdownButton<String>(
        isExpanded: true,
        underline: const SizedBox(),
        hint: const Text('Rôle principal', style: TextStyle(fontSize: 13),),
        
        value: selectedValue,
        onChanged: (newValue) => setState(() {
          selectedValue = newValue;
          errors.remove('compte');
        }),
        items: compte
            .map((String value) => DropdownMenuItem(
                  value: value,
                  child: Text(value),
                ))
            .toList(),
      ),
    );
  }
}
