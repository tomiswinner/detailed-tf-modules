# detailed-terraform-book

# detailed-tf-modules

## source ファイルの更新をする

```sh
# どちらか
tf init -backend-config="../../../backend.hcl"

tf get -update
```

## リソース全ての tag をつけたい場合

```hcl
provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      Owner = "team-alpha"
      ManagedBy = "terraform"
    }
  }
}
```
