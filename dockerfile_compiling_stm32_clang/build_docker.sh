#!/bin/bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
IMAGE_NAME="${IMAGE_NAME:-imagem_teste_stm}"
PROJECT_DIR="${PROJECT_DIR:-$REPO_ROOT}"
BUILD_TYPE="${BUILD_TYPE:-Debug}"
TARGET_NAME="${TARGET_NAME:-all}"

usage() {
    cat <<EOF
Uso:
  ./build_docker.sh all       -> constrói a imagem e compila o projeto
  ./build_docker.sh build     -> só constrói a imagem Docker
  ./build_docker.sh clean     -> apaga a pasta build do projeto
  ./build_docker.sh debug     -> valida o caminho do projeto e mostra configuração
  ./build_docker.sh help      -> mostra esta ajuda

Variáveis úteis:
  PROJECT_DIR=/caminho/para/projeto ./build_docker.sh all
  IMAGE_NAME=nome_da_imagem ./build_docker.sh all
  BUILD_TYPE=Release ./build_docker.sh all
  TARGET_NAME=firmware ./build_docker.sh all

Observação:
  O diretório do projeto precisa conter CMakeLists.txt.
  Se estiver montando um projeto externo, use PROJECT_DIR.
EOF
}

check_project_dir() {
    if [[ ! -d "$PROJECT_DIR" ]]; then
        echo "Erro: diretório do projeto não existe: $PROJECT_DIR" >&2
        echo "Use PROJECT_DIR=/caminho/para/projeto ./build_docker.sh all" >&2
        return 1
    fi

    if [[ ! -f "$PROJECT_DIR/CMakeLists.txt" ]]; then
        echo "Erro: '$PROJECT_DIR' não parece ser um projeto CMake (sem CMakeLists.txt)." >&2
        echo "Use PROJECT_DIR=/caminho/para/projeto ./build_docker.sh all" >&2
        return 1
    fi
}

build_image() {
    echo "Construindo imagem: $IMAGE_NAME"
    docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"
}

configure_and_build() {
    check_project_dir

    echo "Usando projeto em: $PROJECT_DIR"
    rm -rf "$PROJECT_DIR/build"

    docker run --rm \
        -v "$PROJECT_DIR:/workspace" \
        -w /workspace \
        -u "$(id -u):$(id -g)" \
        -e HOME=/tmp \
        "$IMAGE_NAME" \
        bash -lc "
            cmake --no-warn-unused-cli \
                -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} \
                -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=TRUE \
                -DCMAKE_C_COMPILER:FILEPATH=arm-none-eabi-gcc \
                -DCMAKE_CXX_COMPILER:FILEPATH=arm-none-eabi-g++ \
                -S. -B./build -G Ninja && \
            cmake --build ./build --config ${BUILD_TYPE} --target ${TARGET_NAME}
        "
}

clean_project() {
    if [[ -d "$PROJECT_DIR/build" ]]; then
        rm -rf "$PROJECT_DIR/build"
        echo "build removido de: $PROJECT_DIR/build"
    else
        echo "Nada para limpar em: $PROJECT_DIR/build"
    fi
}

main() {
    case "${1:-all}" in
        all)
            build_image
            configure_and_build
            ;;
        build)
            build_image
            ;;
        clean)
            clean_project
            ;;
        debug)
            echo "SCRIPT_DIR=$SCRIPT_DIR"
            echo "REPO_ROOT=$REPO_ROOT"
            echo "PROJECT_DIR=$PROJECT_DIR"
            echo "IMAGE_NAME=$IMAGE_NAME"
            echo "BUILD_TYPE=$BUILD_TYPE"
            echo "TARGET_NAME=$TARGET_NAME"
            check_project_dir
            ;;
        help|-h|--help)
            usage
            ;;
        *)
            echo "Comando desconhecido: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
}

main "$@"