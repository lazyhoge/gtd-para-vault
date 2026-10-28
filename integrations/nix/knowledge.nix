{ config, pkgs, ... }:

let
  # 週次レビューの下ごしらえ（~/vault/procedures/weekly-review.md）。
  # 暫定の仕組みで、実行基盤（Hermes など）を採用したら外す。
  # スクリプト本体は素の .sh に置く（Nix の文字列に埋めると、シェルの ${} のエスケープが要るため）。
  weeklyReview = pkgs.writeShellApplication {
    name = "lh-weekly-review";
    # claude は意図的に runtimeInputs に入れない。システムに入っている claude を周囲の PATH から引く。
    runtimeInputs = with pkgs; [
      coreutils
      git
      libnotify
    ];
    text = ''
      export LH_VAULT_DIR=${config.home.homeDirectory}/vault
    '' + builtins.readFile ./weekly-review.sh;
  };

  # vault のタスクと Project の問い合わせ（lh-vault next など）。
  # 本体は他の実行基盤とも共有するので vault 側（~/vault/procedures/vault-query.sh）に置き、
  # ここでは PATH に名前を出して依存を揃えるだけにする。
  vaultQuery = pkgs.writeShellApplication {
    name = "lh-vault";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      gawk
      gnugrep
      gnused
      jq
      yq-go
    ];
    text = ''
      exec bash ${config.home.homeDirectory}/vault/procedures/vault-query.sh "$@"
    '';
  };

  # 繰り返しのタスクの毎朝の手入れ（過ぎた回の削除・終わった回の片付け・次の回の生成）。
  # 本体は vault 側（~/vault/procedures/recur-daily.sh）。Claude は起動せず bash だけで動く。
  recurDaily = pkgs.writeShellApplication {
    name = "lh-recur";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      gawk
      gnugrep
      gnused
      git
      jq
      yq-go
      taskwarrior3
      libnotify
    ];
    text = ''
      log=''${XDG_CACHE_HOME:-$HOME/.cache}/lh-recur.log
      if ! bash ${config.home.homeDirectory}/vault/procedures/recur-daily.sh "$@" > "$log" 2>&1; then
        notify-send -u critical -a "繰り返しのタスク" "毎朝の手入れに失敗した" "ログ: ~/.cache/lh-recur.log" \
          || echo "失敗の通知を出せなかった" >&2
        exit 1
      fi
    '';
  };
in
{
  # 知識ベース (~/vault) 用。vault 側の設定は ~/vault/.obsidian に入っており
  # git 管理されているため、ここではパッケージと定時実行のタイマーのみ。
  home.packages = [ pkgs.obsidian weeklyReview vaultQuery recurDaily ];

  systemd.user.services.lh-recur = {
    Unit.Description = "vault の繰り返しのタスクを手入れする";
    Service = {
      Type = "oneshot";
      ExecStart = "${recurDaily}/bin/lh-recur";
    };
  };

  systemd.user.timers.lh-recur = {
    Unit.Description = "繰り返しのタスクの手入れ（毎朝 4:00）";
    Timer = {
      # 起きる前に今日の回を揃える。Persistent で、止まっている間に跨いだ分は次回起動時に 1 度だけ拾う
      OnCalendar = "*-*-* 04:00";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  systemd.user.services.lh-weekly-review = {
    Unit.Description = "vault の週次レビューを下ごしらえする";
    Service = {
      Type = "oneshot";
      ExecStart = "${weeklyReview}/bin/lh-weekly-review";
      # ユーザーサービスの PATH にはシステムのパッケージが無いので、claude のために足す
      Environment = [ "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/%u/bin" ];
    };
  };

  systemd.user.timers.lh-weekly-review = {
    Unit.Description = "週次レビューの下ごしらえ（金曜 18:00）";
    Timer = {
      # 本人が選んだ時刻。Persistent で、止まっている間に跨いだ分は次回起動時に 1 度だけ拾う
      OnCalendar = "Fri 18:00";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
