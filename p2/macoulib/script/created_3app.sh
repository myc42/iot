#!/bin/bash

SUCCESS=true
PROJET="projet"

mkdir -p "$PROJET" || SUCCESS=false
[ "$SUCCESS" = true ] || { echo false; exit 1; }

for i in {1..3}; do
  mkdir -p "$PROJET/app$i" || SUCCESS=false
  [ "$SUCCESS" = true ] || { echo false; exit 1; }

  cat > "$PROJET/app$i/app$i.html" <<EOF
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>app$i</title>
</head>
<body>
    <h1>Bienvenue dans app$i</h1>
</body>
</html>
EOF

  [ "$?" -eq 0 ] || { echo false; exit 1; }

  cat > "$PROJET/app$i/Dockerfile" <<EOF
FROM nginx:alpine
COPY app$i.html /usr/share/nginx/html/index.html
EOF

  [ "$?" -eq 0 ] || { echo false; exit 1; }
done

cat > "$PROJET/compose.yaml" <<'EOF'
services:
  app1:
    build:
      context: ./app1
      dockerfile: Dockerfile
    ports:
      - "8081:80"

  app2:
    build:
      context: ./app2
      dockerfile: Dockerfile
    ports:
      - "8082:80"

  app3:
    build:
      context: ./app3
      dockerfile: Dockerfile
    ports:
      - "8083:80"
EOF

[ "$?" -eq 0 ] || { echo false; exit 1; }

echo true
exit 0
