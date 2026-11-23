# Noite Quest

Mini game 8-bit em Flutter para jogar no tempo certo e dormir bem. Cada noite é uma fase com 5 missões:

1. Escolher o jogo da noite (com etiquetas: livre, com limite, só sexta e sábado)
2. Armar o alarme de última partida
3. Jogar com cronômetro (barra de vida que esvazia)
4. Ir deitar no horário
5. Contar como acordou, com a meta de acordar entre 05h40 e 06h00

Tem XP, níveis, estrelas, sequência de noites e o baú de sábado: cumprindo as noites de segunda a quinta, ganha +60 min no sábado.

## Como instalar

- **Android:** abra a página de [Releases](../../releases/latest) no celular, baixe o `NoiteQuest.apk` e toque nele para instalar. Na primeira vez, o Android pede para permitir apps de fontes desconhecidas.
- **iPhone ou PC:** abra a versão web (link na descrição do repositório). No celular, use "Adicionar à tela inicial" para ela virar um app.

O progresso fica salvo no próprio aparelho.

## Como funciona o build

Não precisa instalar nada. A cada push na `main`, o GitHub Actions (`.github/workflows/build.yml`):

1. gera as pastas `android/` e `web/` com `flutter create`
2. cria os ícones a partir de `assets/icon.png`
3. publica a versão web no GitHub Pages
4. cria uma Release com o `NoiteQuest.apk`

## Código

- `lib/logic.dart`: rotina, limites de cada noite, XP e save local
- `lib/sprites.dart`: pixel art e cena animada
- `lib/main.dart`: telas

Fontes: Press Start 2P e Pixelify Sans, licença SIL Open Font License (arquivos em `assets/fonts`).
