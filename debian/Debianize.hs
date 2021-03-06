-- To run the test: runhaskell --ghc-arg=-package-db=dist/package.conf.inplace debian/Debianize.hs --dry-run

import Control.Exception (throw)
import Control.Lens
import Control.Monad.State (evalStateT)
import Data.Map as Map (insert)
import Data.Set as Set (insert)
import Data.Text as Text (pack)
import Data.Version (Version(Version))
import Debian.Debianize
import Debian.Debianize.Output (performDebianization)
import Debian.Debianize.Optparse (parseProgramArguments, CommandLineOptions(..))
import Debian.Relation (BinPkgName(BinPkgName), Relations, parseRelations)
import Distribution.Package (PackageName(PackageName))

main :: IO ()
main = performDebianization customize
    where
      customize :: Monad m => CabalT m ()
      customize =
          do debianDefaults
             -- mapCabal (PackageName "Cabal") (DebBase "cabal-122")
             -- splitCabal (PackageName "Cabal") (DebBase "cabal") (Version [1,22] [])
             -- Force some values so they match the expected results rather than
             -- changing as new package versions arrive.
             (debInfo . control . maintainer) .= parseMaintainer "David Fox <dsf@seereason.com>"
             (debInfo . sourceFormat) .= Native3
             (debInfo . control . standardsVersion) .= Just (StandardsVersion 3 9 3 Nothing)
             (debInfo . compat) .= Just 9
             (debInfo . utilsPackageNameBase) .= Just "cabal-debian"
             (debInfo . binaryDebDescription (BinPkgName "cabal-debian") . relations . depends) %= (++ (rels "apt-file, debian-policy, debhelper, haskell-devscripts (>= 0.8.19)"))
             (debInfo . binaryDebDescription (BinPkgName "libghc-cabal-debian-dev") . relations . depends) %= (++ (rels "debian-policy"))
             (debInfo . atomSet) %= (Set.insert $ InstallCabalExec (BinPkgName "cabal-debian") "cabal-debian" "usr/bin")
             (debInfo . utilsPackageNameBase) .= Just "cabal-debian"
             (debInfo . control . homepage) .= Just (pack "https://github.com/ddssff/cabal-debian")

rels :: String -> Relations
rels = either (throw . userError . show) id . parseRelations
