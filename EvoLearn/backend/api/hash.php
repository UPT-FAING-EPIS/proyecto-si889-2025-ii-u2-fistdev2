<?php
// Escribe la contraseña que deseas usar aquí
$mi_nueva_password = '72943816';

$hash_generado = password_hash($mi_nueva_password, PASSWORD_DEFAULT);

echo "La contraseña es: " . $mi_nueva_password . "<br>";
echo "El hash que debes guardar en la base de datos es:<br>";
echo "<b>" . $hash_generado . "</b>";
?>