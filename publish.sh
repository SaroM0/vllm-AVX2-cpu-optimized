#!/bin/bash
# Script helper para publicar el repositorio en GitHub

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=========================================="
echo "vLLM CPU Optimized - GitHub Publisher"
echo -e "==========================================${NC}"
echo ""

# Check if git is configured
if ! git config user.name &> /dev/null || ! git config user.email &> /dev/null; then
    echo -e "${RED}Git no está configurado!${NC}"
    echo ""
    echo "Configura git primero:"
    echo "  git config --global user.name \"Tu Nombre\""
    echo "  git config --global user.email \"tu@email.com\""
    echo ""
    exit 1
fi

# Ask for GitHub username
echo -e "${YELLOW}Paso 1: Usuario de GitHub${NC}"
read -p "Ingresa tu usuario de GitHub: " GITHUB_USER

if [ -z "$GITHUB_USER" ]; then
    echo -e "${RED}Usuario requerido!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✓ Usuario: $GITHUB_USER${NC}"
echo ""

# Check if remote already exists
if git remote get-url origin &> /dev/null; then
    echo -e "${YELLOW}⚠ Remote 'origin' ya existe${NC}"
    EXISTING_REMOTE=$(git remote get-url origin)
    echo "  Remote actual: $EXISTING_REMOTE"
    echo ""
    read -p "¿Reemplazar? (y/n): " REPLACE
    if [[ $REPLACE =~ ^[Yy]$ ]]; then
        git remote remove origin
        echo -e "${GREEN}✓ Remote removido${NC}"
    else
        echo "Manteniendo remote existente"
    fi
fi

# Add remote if not exists
if ! git remote get-url origin &> /dev/null; then
    REPO_URL="https://github.com/$GITHUB_USER/vllm-cpu-optimized.git"
    git remote add origin "$REPO_URL"
    echo -e "${GREEN}✓ Remote agregado: $REPO_URL${NC}"
fi

echo ""
echo -e "${YELLOW}Paso 2: Crear Repositorio en GitHub${NC}"
echo ""
echo "Opciones:"
echo "  1) Abrir GitHub en el navegador (crear manualmente)"
echo "  2) Usar GitHub CLI (gh) - automático"
echo "  3) Saltear (ya lo creé)"
echo ""
read -p "Selecciona opción (1/2/3): " OPTION

case $OPTION in
    1)
        echo ""
        echo "Abriendo GitHub..."
        echo ""
        echo -e "${YELLOW}Instrucciones:${NC}"
        echo "  1. Repository name: vllm-cpu-optimized"
        echo "  2. Description: CPU-optimized build of vLLM for CPUs without AVX512"
        echo "  3. Visibility: Public"
        echo "  4. NO marcar 'Add README', 'Add .gitignore', ni 'Choose license'"
        echo "  5. Click 'Create repository'"
        echo ""
        
        # Try to open browser
        if command -v xdg-open &> /dev/null; then
            xdg-open "https://github.com/new" &
        elif command -v open &> /dev/null; then
            open "https://github.com/new"
        else
            echo "Abre manualmente: https://github.com/new"
        fi
        
        echo ""
        read -p "Presiona ENTER cuando hayas creado el repositorio..."
        ;;
    2)
        if ! command -v gh &> /dev/null; then
            echo -e "${RED}GitHub CLI (gh) no está instalado${NC}"
            echo "Instala desde: https://cli.github.com/"
            exit 1
        fi
        
        echo ""
        echo "Creando repositorio con gh..."
        gh repo create vllm-cpu-optimized --public \
            --description "CPU-optimized build of vLLM for CPUs without AVX512 support" \
            --source=. \
            --remote=origin
        echo -e "${GREEN}✓ Repositorio creado${NC}"
        ;;
    3)
        echo -e "${GREEN}✓ Ok, continuando...${NC}"
        ;;
    *)
        echo -e "${RED}Opción inválida${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${YELLOW}Paso 3: Push a GitHub${NC}"
echo ""
read -p "¿Hacer push ahora? (y/n): " DO_PUSH

if [[ $DO_PUSH =~ ^[Yy]$ ]]; then
    echo ""
    echo "Haciendo push..."
    echo ""
    
    if git push -u origin main; then
        echo ""
        echo -e "${GREEN}=========================================="
        echo "✓ ¡Repositorio Publicado!"
        echo -e "==========================================${NC}"
        echo ""
        echo "Tu repositorio está en:"
        echo "  https://github.com/$GITHUB_USER/vllm-cpu-optimized"
        echo ""
        echo -e "${YELLOW}Próximos pasos:${NC}"
        echo "  1. Agregar topics al repositorio"
        echo "  2. Habilitar Discussions"
        echo "  3. Crear primera release (v1.0.0)"
        echo "  4. Compartir en redes sociales"
        echo ""
        echo "Lee NEXT_STEPS.md para detalles completos"
        echo ""
    else
        echo ""
        echo -e "${RED}Error al hacer push${NC}"
        echo ""
        echo "Posibles soluciones:"
        echo "  1. Verifica que creaste el repositorio en GitHub"
        echo "  2. Configura autenticación (token o SSH)"
        echo "  3. Verifica el nombre de usuario"
        echo ""
        echo "Para autenticación con token:"
        echo "  https://github.com/settings/tokens"
        echo ""
        exit 1
    fi
else
    echo ""
    echo "Push cancelado. Hazlo manualmente cuando estés listo:"
    echo "  git push -u origin main"
    echo ""
fi

# Open repository in browser
read -p "¿Abrir el repositorio en el navegador? (y/n): " OPEN_BROWSER

if [[ $OPEN_BROWSER =~ ^[Yy]$ ]]; then
    REPO_WEB="https://github.com/$GITHUB_USER/vllm-cpu-optimized"
    if command -v xdg-open &> /dev/null; then
        xdg-open "$REPO_WEB" &
    elif command -v open &> /dev/null; then
        open "$REPO_WEB"
    else
        echo "Abre manualmente: $REPO_WEB"
    fi
fi

echo ""
echo -e "${GREEN}¡Gracias por contribuir al código abierto! 🎉${NC}"
echo ""

