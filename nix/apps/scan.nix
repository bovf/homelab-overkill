{ nixpkgs, ... }:

{
  mkScanApp = system:
    let
      pkgs = import nixpkgs { inherit system; };
      script = pkgs.writeShellApplication {
        name = "scan";
        runtimeInputs = with pkgs; [ gitleaks trufflehog jq ];
        text = ''
          echo "=== gitleaks (.gitleaksignore applied) ==="
          gl=0
          gitleaks git . --no-banner --redact || gl=$?
          echo ""

          echo "=== trufflehog (verified only, .trufflehog-allowlist applied) ==="
          allowlist_file=".trufflehog-allowlist"
          findings_count=0
          tmp_json=$(mktemp)
          trap 'rm -f "$tmp_json"' EXIT

          trufflehog --no-update --no-color --json git file://. --only-verified \
            > "$tmp_json" 2>/dev/null || true

          while IFS= read -r line; do
            [ -z "$line" ] && continue
            detector=$(echo "$line" | jq -r '.DetectorName // ""')
            commit=$(echo "$line"   | jq -r '.SourceMetadata.Data.Git.commit // ""')
            file=$(echo "$line"     | jq -r '.SourceMetadata.Data.Git.file // ""')
            fline=$(echo "$line"    | jq -r '.SourceMetadata.Data.Git.line // ""')
            fp="$detector:$commit:$file:$fline"

            if [ -f "$allowlist_file" ] && \
               awk -F'#' '{ gsub(/[[:space:]]+$/, "", $1); print $1 }' "$allowlist_file" \
               | grep -vE '^$' \
               | grep -qFx "$fp"; then
              continue
            fi

            echo "[$detector] $file:$fline ($(echo "$commit" | cut -c1-8))"
            findings_count=$((findings_count + 1))
          done < "$tmp_json"

          th=0
          if [ "$findings_count" -gt 0 ]; then
            th=1
            echo "→ $findings_count verified, non-allowlisted finding(s) above."
          fi
          echo ""

          if [ $gl -eq 0 ] && [ $th -eq 0 ]; then
            echo "OK — both scanners clean"
            exit 0
          fi
          echo "FAIL — gitleaks=$gl trufflehog=$th"
          exit 1
        '';
      };
    in {
      type = "app";
      program = "${script}/bin/scan";
    };
}
