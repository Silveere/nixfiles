let
  pkgs = import <nixpkgs> {};
  lib = pkgs.lib;

  rpi4 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG0FSLInClzASv4Ul0bZ5Rxa59M7ExyCYt1emHOwztGr";
  nullbox = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPXbOKHkWi04pCrbs6AyYgB4Im74akpqlTwC9NkL+MKe";
  slab = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOEo2nseQPm2jtiKXJMk9wOWrfIYSAbQwWEqtksHsftB";

  all-user = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC6HOSwsMvNtv6iOxDLhSTnjREyAIGXoQ5IgC/mXfAIT9vA59fbI74wjdzbIUd9sZLd4mIExhdKw5ihaSOmsIb2x4tokjIHvjsdWJVBXqwqoYCd+9S4aoi5Nc0YHLCqTQM7LqJTCbE6HzLqkiZNhocgAnEIXpgcpnf0kB7suFXSKY/XY2ALFYXVohPfZTQsJqfkGkkVTgzglFV8kaVUeas0vLsDVU73lQjZ1oO4n2Ps+O9jbjFp3Zk/5txcKO3rVEqEy8vJLHIHFXnqo/2WOiM/ZagwoDXBwGZjH++klVwBb1Bu6MKbahI986gamVrWPgoRr/AaeC/WkVXIG3Yi4BG6sxhTlYoO3MwfnaQNetAAfT6XmzifTxtCGxIM5MdwC0n19C2qLwAU6EXhW0/W7RPqdsA5BcsQX9Fg+3yJX/xVwAeiRE5DzyI8aCkemXn7y7BAAbXG+e3YEetUrNjdRNWIeMrGv8LckE5z5sfifbwks5+++K+1X256bGX93m7Nn7U="
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC4eg1TMjggwqdur1bsBqz4wzLchxAfcVl9XPJQ/Z4NCjKD+/lqmUQNt1n5ld5w/fRirkcsOIcoWSW1ioisvoZEtv5I5clQLLHA4sNIO2hXnNP3+XF+pB/eBZ6my4/nySl1QkDBEFE7HDTw0S6aZAkk3xoD08W2mU4xcVnVUeBUGyOy2Wt8NESYqwfw0qcIyRd37YmlOk22v/aVlMAsBSI73ug7/qTsVFp8G1py2BLi0ZwA5MfiZ8LZ6Y9gXFVGAA1pi2TiG+PVRMe9HsVHrxYX7crx6XnWmaa2o1KmxqWXriTd8zO2OGgoCW8klIeKnsJ3fGXJlLpcgxOXwg9vkE3EjWyihRrzooQdcfgrdxs7CY4D9OY2HrJ66h/bOtQgQCjI6/jN8SB+thhktj8fF5kSpB2hnquZPddVaRl83EmDqx03eqPVWtoGfEFi5/M6LGcqu8dYVoKioFnMFWaZVxlIn0goNCF6eV4+xPtFn/Wt6o4twYKJVEVXbhFQbiebUgk="
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC0enlNbo1V5q0yq6n90gRPsNznoQ/KLEjeo1yOAUyJwPi35cw+b3p4DRN7T55DcSivKKE9Hyh6bpaQWFJSLyP5jAtDrYkuUfNx5GkgrquMwMvwzk3Z+h2/J/WgDyKQZXtm9LHYTgiW8jDU1lBiks39IqCAGrCTLAmAHSaJ39A4ZpJwu6zZ9sQqT22E/UpFm5MBezdZbm8V0G+beX+y3+pp8Kag7goGNY+rgTgx7REDz3jzZz3FBP+CxKoo1H8HHz78RDqBb8HKpVQYNQkwvIBeczKawRHIkJO2Mk+1mc6Ta6beA9+Uyf+puxco2xl6BOnDInvnhWJIRXOJuR5P8/YWprE1o4ixF2N95D2GlJ618V7faEovu/sNj8qIvfA66OF1gG+LOfNAl+u2+3V8ewATF493F0q04zhenoH1ZdrsACJfL8tK9Ev9056ImR6aSJ5BjqCk0tMmnLKTZ7q3R2LoKnB1r/TXe10OH7rx5BDAt4OmD8a5QS0RvVgK3O/iMW0="
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDSAD3bCc9ZHGqU+HoCtp69uU3Px5bbVYYrHbLS3AS1Xku9rPKE/oUU/fz8/AZxp6dLuKhPjQjLzgbFjM0rK57fiOPqBnlw3eAiIymrlB03ALLV3y+GF2OhVf2rkcPkUxjK978dwS9bxgty6WzPAoSjNwilzgf2CcLcHyIzDwwzWCndM9jtpXbUbLhOH6CvsvygBD7j06wakLOorTS+cAFecUvaUkDr6gSu6zpM29DcFiq8T1VoWhBzwC/9IKnxV/XqaZBM3Em7NfPQIzYWcD9A5+Holj2I6jcTSd9xIdMhD4Miqm8IdojPkP2NuVfD9AMxn0ccwbROG/zliyXtcxRj8b3jEquBKuN+yGqF5hexmKlhHmHua9NwhsWnGWjOWWSaPtsp3WOM/fEc7cWpVWZ+W8V5LbdWEY3Ke52Cz35QbOSml09H/gIzsMxZbiZvkJB4PvWKf0FoyZ8ojJWIaGP1/LQdXNMWorqy7tWp3sAw3JcMsR0ezJ3YoI6Y6FOIdL0="
  ];
in {
  "cloudflare-dns.age".publicKeys = [rpi4] ++ all-user;
  "wireguard-rpi4.age".publicKeys = [rpi4] ++ all-user;
  "htpasswd.age".publicKeys = [rpi4] ++ all-user;
  "htpasswd-cam.age".publicKeys = [rpi4] ++ all-user;
  "authelia-users.age".publicKeys = [rpi4] ++ all-user;
  "authelia-storage.age".publicKeys = [rpi4] ++ all-user;
  "authelia-jwt.age".publicKeys = [rpi4] ++ all-user;
  "authelia-session.age".publicKeys = [rpi4] ++ all-user;
  "homepage.age".publicKeys = [rpi4] ++ all-user;
  "paperless-admin.age".publicKeys = [rpi4] ++ all-user;

  "restic-rclone.age".publicKeys = [rpi4 nullbox slab] ++ all-user;
  "restic-password.age".publicKeys = [rpi4 nullbox slab] ++ all-user;

  "anki-user.age".publicKeys = [rpi4] ++ all-user;
}
