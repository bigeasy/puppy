UPDATE Activation SET activated = TRUE WHERE NOT activated AND code = $1
