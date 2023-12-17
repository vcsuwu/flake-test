{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = { self, nixpkgs, devenv, systems, ... } @ inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      packages = forEachSystem (system: {
        devenv-up = self.devShells.${system}.default.config.procfileScript;
      });

      devShells = forEachSystem
        (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          {
            default = devenv.lib.mkShell {
              inherit inputs pkgs;
              modules = [({ pkgs, config, ...}:
                {
                  # https://devenv.sh/reference/options/
                  packages = [];

                  enterShell = ''
                  '';
		  languages.php = {
		    enable = true;
		    fpm.pools.web.settings = {
		    "clear_env" = "no";
		    "pm" = "dynamic";
		    "pm.max_children" = 10;
		    "pm.start_servers" = 2;
		    "pm.min_spare_servers" = 1;
		    "pm.max_spare_servers" = 10;
		    };
		  };

		  services.nginx = {
		    enable = true;
		    httpConfig = ''
		    server {
		      listen 8080 default_server;
		      root ${~/project/basic/web};
		      index index.php index.html;
		      location / {
		        try_files $uri $uri/ =404;
		      }
		      location ~ \.php$ {
		        fastcgi_pass unix:${config.languages.php.fpm.pools.web.socket};
		      }
		    }
		    '';

		  };
                }
		)
              ];
            };
          });
    };
}
