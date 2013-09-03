find the latest commit id for a given branch in a remote repository:
git ls-remote git@github.com:manuelkiessling/projectile refs/heads/master | cut -f1

find the latest commit id for a given local branch (must be checked out!)
git log -n 1 refs/heads/health --pretty=format:"%H"
