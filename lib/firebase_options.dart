// Configuración pública de Firebase. No es secreta: las reglas de Firestore protegen los datos.
// - Real: proyecto cabletech-81e62, app Android «Torrexi» (android/app/google-services.json).
// - Pruebas: proyecto torrexi-pruebas, app «Torrexi PRUEBAS» (android/app/src/pruebas/google-services.json),
//   base aparte que no toca los datos reales. Se compila con `--flavor pruebas`.
import "package:firebase_core/firebase_core.dart";
import "package:flutter/services.dart" show appFlavor;

/// Verdadero en el APK de prueba (compilado con `--flavor pruebas`).
const esPruebas = appFlavor == "pruebas";

const _real = FirebaseOptions(
  apiKey: "AIzaSyA88DdbH156sQ6Wk75vWwdZIK4Pe-JFvDw",
  appId: "1:1085454478818:android:16e3a542126769d282ddbb",
  messagingSenderId: "1085454478818",
  projectId: "cabletech-81e62",
  storageBucket: "cabletech-81e62.firebasestorage.app",
);

const _pruebas = FirebaseOptions(
  apiKey: "AIzaSyBYjuD2vbZ1mn-Jwks93bwsPGC0kZifNUI",
  appId: "1:357964544064:android:fb1ba2b8813204ee84c7a5",
  messagingSenderId: "357964544064",
  projectId: "torrexi-pruebas",
  storageBucket: "torrexi-pruebas.firebasestorage.app",
);

const firebaseOptions = esPruebas ? _pruebas : _real;
