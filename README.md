![git-clean](https://user-images.githubusercontent.com/9920336/126655408-0319b806-4919-4c73-82da-1ae3fec39f37.png)

Simple cli program to clean up local git branches that have been deleted on remote.

# Rules
- Branch must have existed on origin at some point
- Branch must be deleted on origin
- Branch is not current working branch

# Installing

```sh
cp git-clean.sh /usr/bin/git-clean
chmod +555 /usr/bin/git-clean
```

# Using (in git repo)
```sh
git-clean
```
