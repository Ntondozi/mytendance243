import 'package:flutter/material.dart';

typedef ValidatorFunction = String? Function(String? value);

ValidatorFunction combineValidators(List<ValidatorFunction> validators) {
  return (String? value) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) return result;
    }
    return null;
  };
}

class Validator {
  static String? isRequired(String? val) {
    if (val == null || val.trim().isEmpty) {
      return "Veuillez remplir ce champ";
    }
    return null;
  }

  static String? email(String? val) {
    if (val == null || val.isEmpty) return "Veuillez entrer un email";
    final regex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (!regex.hasMatch(val)) {
      return "Le format de l'email est incorrect";
    }
    return null;
  }

  static String? phone(String? val) {
    if (val == null || val.isEmpty) return "Veuillez entrer un numéro";
    if (!RegExp(r'^[0-9]{9}$').hasMatch(val)) {
      return "Le numéro doit contenir exactement 9 chiffres";
    }
    return null;
  }

  static ValidatorFunction equalsTo(TextEditingController other) {
    return (String? value) {
      if (value != other.text) {
        return "Les mots de passe sont différents";
      }
      return null;
    };
  }

  static String? villeRequired(String? val, bool isOther) {
    if (isOther && (val == null || val.trim().isEmpty)) {
      return "Veuillez entrer votre ville";
    }
    return null;
  }
  static String? password(String? val) {
  if (val == null || val.trim().isEmpty) {
    return "Veuillez entrer un mot de passe";
  }
  if (val.length < 6) {
    return "Le mot de passe doit contenir au moins 6 caractères";
  }
  return null;
}

}
