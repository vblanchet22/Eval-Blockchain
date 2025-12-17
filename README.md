# Système de Vote Décentralisé - Évaluation Blockchain

## Description du Projet

Ce projet implémente un système de vote décentralisé sur la blockchain Ethereum (testnet Sepolia) avec les fonctionnalités suivantes:
- Gestion des candidats par les administrateurs
- Financement des candidats par les fondateurs
- Vote avec NFT de preuve
- Détermination du gagnant
- Workflow en 4 phases avec contrôle d'accès basé sur les rôles

## Technologies Utilisées

- **Solidity**: 0.8.26
- **Framework**: Foundry
- **Bibliothèques**: OpenZeppelin Contracts v5.5.0
- **Testnet**: Sepolia
- **Outils**: Forge, Cast, Anvil

## Architecture du Projet

### Contrats Smart Contracts

#### 1. VotingSystem.sol
Contrat principal qui gère tout le système de vote:
- **Rôles**: ADMIN_ROLE, FOUNDER_ROLE
- **Workflow**: 4 phases (REGISTER_CANDIDATES, FOUND_CANDIDATES, VOTE, COMPLETED)
- **Fonctionnalités**:
  - Ajout de candidats (admin uniquement)
  - Financement de candidats (fondateurs uniquement)
  - Vote avec délai d'1 heure
  - Détermination du gagnant

#### 2. VoteNFT.sol
Contrat NFT (ERC721) pour prouver qu'un utilisateur a voté:
- Mint automatique lors du vote
- Empêche le double vote
- Token unique par votant

## Exigences Implémentées

### ✅ Point 1: Rôle ADMIN_ROLE
- Seuls les admins peuvent ajouter des candidats
- Le déployeur du contrat reçoit automatiquement le rôle ADMIN_ROLE

### ✅ Point 2: Restriction sur addCandidate
- La fonction `addCandidate()` est restreinte aux utilisateurs ayant le rôle ADMIN_ROLE

### ✅ Point 3: Vote ouvert à tous
- N'importe qui peut voter (pas de restriction de rôle sur la fonction `vote()`)

### ✅ Point 4: Workflow en 4 phases
- **REGISTER_CANDIDATES (0)**: Phase d'enregistrement des candidats
- **FOUND_CANDIDATES (1)**: Phase de financement des candidats
- **VOTE (2)**: Phase de vote
- **COMPLETED (3)**: Phase terminée, déclaration du gagnant

### ✅ Point 5: Rôle FOUNDER_ROLE et financement
- Nouveau rôle FOUNDER_ROLE créé
- Fonction `fundCandidate()` permet aux fondateurs d'envoyer des ETH aux candidats
- Fonction active uniquement pendant la phase FOUND_CANDIDATES

### ✅ Point 6: Délai d'1 heure avant le vote
- Lors du passage au statut VOTE, un timestamp `voteStartTime` est enregistré
- Les votes ne sont possibles qu'après `voteStartTime + 1 hour`

### ✅ Point 7: NFT de vote
- Contrat VoteNFT.sol implémentant ERC721
- Chaque votant reçoit automatiquement un NFT unique
- Le NFT empêche le double vote

### ✅ Point 8: Fonction getWinner()
- Détermine le candidat avec le plus de votes
- Accessible uniquement en phase COMPLETED
- Émet un événement WinnerDeclared

### ✅ Point 9: Tests unitaires (37 tests)
- Couverture complète de toutes les fonctionnalités
- Tests des permissions et des workflows
- Tests des cas d'erreur
- Tous les tests passent avec succès

### ✅ Point 10: Déploiement sur Sepolia
- Contrat déployé et vérifié sur Sepolia
- Accessible via Etherscan

## Informations de Déploiement

### Adresses des Contrats (Sepolia)
- **VotingSystem**: `0xCb62182bc4b363d86EE3cc0e0b4841eB0D9a16e6`
- **VoteNFT**: `0xf3A4b70b74cfb7720ac79319fE81bCD075bF55a1`

### Transaction de Déploiement
- **Hash**: `0xd09997e09c1b3aaae80aef36f83af4eef2b3cb904c84a199f7094c9ac613e7d9`
- **Vérification Etherscan**: ✅ Contrat vérifié

### Liens Etherscan
- VotingSystem: https://sepolia.etherscan.io/address/0xCb62182bc4b363d86EE3cc0e0b4841eB0D9a16e6
- VoteNFT: https://sepolia.etherscan.io/address/0xf3A4b70b74cfb7720ac79319fE81bCD075bF55a1

## Tests Réalisés

### Tests Unitaires (37 tests - 100% réussite)

#### Tests de Contrôle d'Accès
1. ✅ Admin role granted to deployer
2. ✅ Admin can add candidates
3. ✅ Non-admin cannot add candidate
4. ✅ Admin can grant roles

#### Tests de Vote
5. ✅ Anyone can vote (when workflow is at VOTE status)
6. ✅ Cannot vote twice
7. ✅ Cannot vote for invalid candidate
8. ✅ Vote count increases correctly

#### Tests de Candidats
9. ✅ Cannot add empty candidate name
10. ✅ Multiple candidates can be added
11. ✅ Get candidate information

#### Tests de Workflow
12. ✅ Initial workflow status is REGISTER_CANDIDATES
13. ✅ Admin can change workflow status
14. ✅ Non-admin cannot change workflow status
15. ✅ Cannot add candidate when not in REGISTER_CANDIDATES status
16. ✅ Cannot vote when not in VOTE status
17. ✅ WorkflowStatusChanged event is emitted

#### Tests de Financement
18. ✅ Founder can send funds to candidate
19. ✅ Non-founder cannot send funds to candidate
20. ✅ Cannot send funds when not in FOUND_CANDIDATES status
21. ✅ Cannot send funds to invalid candidate
22. ✅ Cannot send zero funds
23. ✅ FundsSentToCandidate event is emitted
24. ✅ Multiple founders can send funds to same candidate

#### Tests de Délai de Vote
25. ✅ Cannot vote before 1 hour after VOTE status is set
26. ✅ Can vote after 1 hour from VOTE status activation
27. ✅ voteStartTime is set when VOTE status is activated
28. ✅ voteStartTime is only set for VOTE status

#### Tests NFT
29. ✅ Voter receives NFT after voting
30. ✅ Cannot vote if already owns NFT
31. ✅ VoteCast event is emitted with NFT token ID
32. ✅ Multiple voters each receive unique NFT

#### Tests de Gagnant
33. ✅ Cannot get winner when not in COMPLETED status
34. ✅ Can get winner when in COMPLETED status
35. ✅ Winner is correctly determined with multiple candidates
36. ✅ WinnerDeclared event is emitted
37. ✅ Winner can be determined with no votes
38. ✅ Cannot get winner if no candidates registered

### Tests sur Sepolia (Tests Manuels via Etherscan)

#### Phase 1: Enregistrement des Candidats
- ✅ Ajout de 3 candidats: "Valentin", "Alice", "Bob"
- ✅ Vérification des candidats avec `getCandidate()`

#### Phase 2: Attribution du Rôle FOUNDER
- ✅ Récupération du hash FOUNDER_ROLE
- ✅ Attribution du rôle FOUNDER_ROLE au compte de test

#### Phase 3: Transition vers VOTE
- ✅ Changement du workflow vers le statut VOTE (2)
- ✅ Vérification du `voteStartTime`

#### Tests en Attente (nécessitent 1 heure d'attente)
- ⏳ Vote pour un candidat
- ⏳ Vérification du NFT reçu
- ⏳ Test de double vote (devrait échouer)
- ⏳ Passage en phase COMPLETED
- ⏳ Récupération du gagnant avec `getWinner()`

## Structure du Projet

```
BlockChain/
├── src/
│   ├── VotingSystem.sol      # Contrat principal de vote
│   └── VoteNFT.sol            # Contrat NFT ERC721
├── script/
│   └── DeployVotingSystem.s.sol  # Script de déploiement
├── test/
│   └── VotingSystem.t.sol     # Tests unitaires (37 tests)
├── lib/
│   └── openzeppelin-contracts/  # Dépendances OpenZeppelin
├── .env                       # Variables d'environnement (non versionné)
├── .gitignore                 # Fichiers ignorés par Git
├── foundry.toml               # Configuration Foundry
└── README.md                  # Ce fichier
```

## Installation et Utilisation

### Prérequis
- Foundry installé
- Node.js (optionnel)
- Un wallet avec des Sepolia ETH

### Installation des Dépendances
```bash
forge install OpenZeppelin/openzeppelin-contracts@v5.5.0
```

### Compilation
```bash
forge build
```

### Tests
```bash
forge test
# ou avec verbosité
forge test -vvv
```

### Déploiement
```bash
# Configuration des variables d'environnement dans .env
SEPOLIA_RPC_URL=<votre_url_rpc>
PRIVATE_KEY=<votre_clé_privée>
ETHERSCAN_API_KEY=<votre_clé_api>

# Déploiement
forge script script/DeployVotingSystem.s.sol:DeployVotingSystem --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
```

## Fonctionnalités Clés

### Gestion des Rôles
- **DEFAULT_ADMIN_ROLE**: Peut gérer tous les rôles
- **ADMIN_ROLE**: Peut ajouter des candidats et changer le workflow
- **FOUNDER_ROLE**: Peut financer des candidats

### Événements
- `WorkflowStatusChanged`: Émis lors du changement de phase
- `FundsSentToCandidate`: Émis lors du financement d'un candidat
- `VoteCast`: Émis lors d'un vote (avec ID du NFT)
- `WinnerDeclared`: Émis lors de la déclaration du gagnant

### Sécurité
- Protection contre le double vote (mapping + NFT)
- Contrôle d'accès basé sur les rôles (AccessControl)
- Validation des inputs (candidat valide, montant > 0)
- Workflow strict (impossible de voter hors phase VOTE)

## Résultats

- ✅ Tous les tests unitaires passent (37/37)
- ✅ Contrat déployé sur Sepolia
- ✅ Contrat vérifié sur Etherscan
- ✅ Tests manuels en cours sur Etherscan
- ✅ Pipeline CI/CD GitHub (forge fmt, forge test)

## Repository GitHub

https://github.com/vblanchet22/Eval-Blockchain

---

**Auteur**: Valentin Blanchet
**Date**: 17 Décembre 2025
**Cours**: Dev Blockchain - Évaluation
