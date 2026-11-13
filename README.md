# ONLYOFFICE Desktop Editors para Nix/NixOS

Empacota o **ONLYOFFICE Desktop Editors 10.0.0-169** (`onlyoffice-desktopeditors_amd64.deb`)
como um pacote Nix, com um módulo NixOS para instalação declarativa.

O `.deb` **não** fica no repositório: ele é baixado do release oficial via
`fetchurl`, com hash fixo. Isso mantém o repositório pequeno e compatível com o
limite de 100 MB por arquivo do GitHub.

## Uso rápido

```bash
nix build
./result/bin/onlyoffice-desktopeditors

# versão
./result/bin/onlyoffice-desktopeditors --version
# ONLYOFFICE ver. 10.0.0.169

# sem criar o link result
nix run .
```

## Publicar no GitHub

O arquivo `onlyoffice-desktopeditors_amd64.deb` local está no `.gitignore` e
não deve ser enviado. O repositório precisa conter apenas:

```
flake.nix
flake.lock
package.nix
default.nix
README.md
.gitignore
```

Crie o repositório e envie:

```bash
cd /home/matheus/Projects/onlyofficenix
git init -b main
git add .
git status   # confirme que o .deb NÃO aparece na lista

git commit -m "OnlyOffice Desktop Editors 10.0.0-169 para Nix"

# opção 1: criar o repositório remoto com o gh
gh repo create matheusrosafogo/onlyoffice-nix \
  --public --source=. --remote=origin --push

# opção 2: repositório já criado
git remote add origin git@github.com:matheusrosafogo/onlyoffice-nix.git
git push -u origin main
```

## Usar como input de flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    onlyoffice.url = "github:matheusrosafogo/onlyoffice-nix";
  };

  outputs = { self, nixpkgs, onlyoffice, ... }: {
    nixosConfigurations.minha-maquina = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        onlyoffice.nixosModules.default
        # ...
      ];
    };
  };
}
```

## Usar no NixOS clássico (o caso deste repositório)

Como o Multipass, o flake pode ser carregado de forma impura com
`builtins.getFlake`. Em `packages/pkgs.nix`:

```nix
let
  var = import ../variables.nix;
  mp = builtins.getFlake "github:matheusrosafogo/multipass-nix";
  oo = builtins.getFlake "github:matheusrosafogo/onlyoffice-nix";
in
{
  imports = [
    mp.nixosModules.default
    oo.nixosModules.default   # adiciona o OnlyOffice ao systemPackages
  ];

  # O restante do módulo continua igual.
}
```

Também é possível instalar sem o módulo, adicionando o pacote diretamente:

```nix
environment.systemPackages = [
  oo.packages.${pkgs.stdenv.hostPlatform.system}.default
];
```

Para fixar um commit específico (recomendado para reprodutibilidade):

```nix
oo = builtins.getFlake "github:matheusrosafogo/onlyoffice-nix/SEU_COMMIT";
```

`builtins.getFlake` exige a feature experimental `flakes` habilitada. O
Multipass já usa esse mesmo recurso, então a configuração atual atende.

## Instalar no perfil do usuário

```bash
nix profile install github:matheusrosafogo/onlyoffice-nix
```

## Atualizar a versão

1. Descubra a nova tag no repositório
   [ONLYOFFICE/DesktopEditors](https://github.com/ONLYOFFICE/DesktopEditors/releases).
2. Atualize a URL em `package.nix` (`/v10.0.0/`).
3. Recalcule o hash:

   ```bash
   nix-prefetch-url --type sha256 \
     https://github.com/ONLYOFFICE/DesktopEditors/releases/download/v10.0.0/onlyoffice-desktopeditors_amd64.deb
   ```

   Converta para SRI com:

   ```bash
   nix hash convert --hash-algo sha256 --to sri <hash-base32>
   ```

4. Atualize `version` e o `hash` em `package.nix`.
5. Valide com `nix build` e `nix flake check`.

## Como o pacote funciona

- O `.deb` é desempacotado pelo hook do `dpkg`.
- `autoPatchelfHook` corrige os binários e bibliotecas para os caminhos do Nix.
- Como o OnlyOffice é binário e espera caminhos do FHS (por exemplo,
  `/usr/bin/curl` para instalar plugins), o resultado é um ambiente
  `buildFHSEnv`.
- O módulo NixOS apenas adiciona o pacote a `environment.systemPackages`.

## Cache binário (opcional, recomendado)

A compilação do ambiente FHS é grande (a aplicação ocupa cerca de 1,1 GB
descompactada). Para não recompilar em cada máquina:

1. Crie um cache no [Cachix](https://app.cachix.org), por exemplo
   `matheusrosafogo-onlyoffice`.
2. Adicione um workflow do GitHub Actions que rode `nix build` e
   `cachix push`.
3. Cadastre o cache em `system/substituters.nix`, como já existe para o
   Multipass.

Sem cache, a primeira instalação em outra máquina baixa o `.deb` e compila
localmente.

## Observações

- Apenas `x86_64-linux`.
- O módulo é silenciosamente ignorado em outras arquiteturas porque o pacote
  não as suporta.
- Fontes da Microsoft (Arial, Calibri, Times New Roman etc.) não são
  distribuídas. Instale-as em `~/.local/share/fonts/` se precisar que os
  modelos padrão sejam exibidos corretamente.
- O hash do `.deb` local usado no desenvolvimento é idêntico ao do release
  oficial: `sha256-IZDttAIqKsL27uD3iBVSDw5Ozh6KEJfGRab5siXItZw=`.
- Licença do pacote upstream: AGPL-3.0 (binário, `sourceProvenance =
  binaryNativeCode`).
