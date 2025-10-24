{ config, ... }:
{

  users.users.engineer = {
    isNormalUser = true;
    description = "Engineer";
    extraGroups = [ "networkmanager" "wheel" ];
    initialPassword = "changeme";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDUXtAezrePsCvDPiIe3dvVuGchOic2nF8bBmuN7CEkqMWhf4x+R5RL8XiVi7WzjOaQGPX6jqLVx8ncxx1p1mfPHoORUKU66OrAVknY5897izsixfgfAXdtj04DzEZO9iP4OHFGqjqu+fgeH6Pbh1+WWocRvg3aR6lhLzfqRl4nhYbHSsmWrT8FPcO8fzgTgayL7JrJzpzkFHcwAk1FWseMWRK3jOBwS5fzw/rQbp3od74yfvm7k0IAg8O76gpyi/EwzquykDTdQYRDrnVc/ALNFx6DLI9JDv96vAkk3sqiB7JLZjmKeUa5TetYeONpo+16+Adjm9AEPSrrNw0SRSX1o024VumA3PEn77J4ItOQ9QCKng0p4yRvFWiKse7YsgWX3bHeSXW+D/EJJknB5eLW1E1Xq5yAVMGuYxXOdINb2gaiYWDDTd8+gfbi9/U9i607I1kiEflJzwKfVCx695RjCZRzhpyiiv46lB+JOCqxKDsap6XBZtK6TN9Frmgd9Gzgw9c9ytx7MabLrI39E0Sn4anDKMmmNvbtOu0WEpgmb+0o5o6H+Tqaw9PAwiy3n4/YUQAbGf9tAxdhmWdBINtk7yDIhF2Q8b91sxLVIwnHxBBVJzs4NSxqsP5pt4Zsrr9U2mDPgDdazBSu2SNxp3tF8oxNBhdOBJz4nxgnau236w== dobrynikolov@Dobrys-MacBook-Air.local"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICoJQa9vHbT65SMInKKKsEaYV7pLZK/oWkoEStXt18F4 engineer@engineer.local"
    ];
  };

  users.users.root= {
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDUXtAezrePsCvDPiIe3dvVuGchOic2nF8bBmuN7CEkqMWhf4x+R5RL8XiVi7WzjOaQGPX6jqLVx8ncxx1p1mfPHoORUKU66OrAVknY5897izsixfgfAXdtj04DzEZO9iP4OHFGqjqu+fgeH6Pbh1+WWocRvg3aR6lhLzfqRl4nhYbHSsmWrT8FPcO8fzgTgayL7JrJzpzkFHcwAk1FWseMWRK3jOBwS5fzw/rQbp3od74yfvm7k0IAg8O76gpyi/EwzquykDTdQYRDrnVc/ALNFx6DLI9JDv96vAkk3sqiB7JLZjmKeUa5TetYeONpo+16+Adjm9AEPSrrNw0SRSX1o024VumA3PEn77J4ItOQ9QCKng0p4yRvFWiKse7YsgWX3bHeSXW+D/EJJknB5eLW1E1Xq5yAVMGuYxXOdINb2gaiYWDDTd8+gfbi9/U9i607I1kiEflJzwKfVCx695RjCZRzhpyiiv46lB+JOCqxKDsap6XBZtK6TN9Frmgd9Gzgw9c9ytx7MabLrI39E0Sn4anDKMmmNvbtOu0WEpgmb+0o5o6H+Tqaw9PAwiy3n4/YUQAbGf9tAxdhmWdBINtk7yDIhF2Q8b91sxLVIwnHxBBVJzs4NSxqsP5pt4Zsrr9U2mDPgDdazBSu2SNxp3tF8oxNBhdOBJz4nxgnau236w== dobrynikolov@Dobrys-MacBook-Air.local"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICoJQa9vHbT65SMInKKKsEaYV7pLZK/oWkoEStXt18F4 engineer@engineer.local"
    ];
  };

  programs.ssh.knownHosts."dobrynikolov-mac" = {
    hostNames = [ "dobrynikolov@Dobrys-MacBook-Air.local" ];
    publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDUXtAezrePsCvDPiIe3dvVuGchOic2nF8bBmuN7CEkqMWhf4x+R5RL8XiVi7WzjOaQGPX6jqLVx8ncxx1p1mfPHoORUKU66OrAVknY5897izsixfgfAXdtj04DzEZO9iP4OHFGqjqu+fgeH6Pbh1+WWocRvg3aR6lhLzfqRl4nhYbHSsmWrT8FPcO8fzgTgayL7JrJzpzkFHcwAk1FWseMWRK3jOBwS5fzw/rQbp3od74yfvm7k0IAg8O76gpyi/EwzquykDTdQYRDrnVc/ALNFx6DLI9JDv96vAkk3sqiB7JLZjmKeUa5TetYeONpo+16+Adjm9AEPSrrNw0SRSX1o024VumA3PEn77J4ItOQ9QCKng0p4yRvFWiKse7YsgWX3bHeSXW+D/EJJknB5eLW1E1Xq5yAVMGuYxXOdINb2gaiYWDDTd8+gfbi9/U9i607I1kiEflJzwKfVCx695RjCZRzhpyiiv46lB+JOCqxKDsap6XBZtK6TN9Frmgd9Gzgw9c9ytx7MabLrI39E0Sn4anDKMmmNvbtOu0WEpgmb+0o5o6H+Tqaw9PAwiy3n4/YUQAbGf9tAxdhmWdBINtk7yDIhF2Q8b91sxLVIwnHxBBVJzs4NSxqsP5pt4Zsrr9U2mDPgDdazBSu2SNxp3tF8oxNBhdOBJz4nxgnau236w== dobrynikolov@Dobrys-MacBook-Air.local";
  };

  programs.ssh.knownHosts."engineer" = {
    hostNames = [ "engineer@engineer.local" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICoJQa9vHbT65SMInKKKsEaYV7pLZK/oWkoEStXt18F4 engineer@engineer.local";
  };
}
