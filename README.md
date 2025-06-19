# detailed-terraform-book

# detailed-tf-modules

## 構文チェック

```sh
terraform validate
```

## フォーマット

```sh
terraform fmt
```

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

## if else 文

```hcl
# リソースを作るかどうかなら count を使う
# if else は作れないので、単純に三項演算子を使う
# bool が true の場合は 1 が返ってくるので、 count = 1 になって、リソースが作られる
# bool が false の場合は 0 が返ってくるので、 count = 0 になって、リソースが作られない
resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  count = var.enable_autoscaling ? 1 : 0
  scheduled_action_name = "scale-out-during-business-hours"
  min_size = 2
  max_size = 10
  desired_capacity = 10
}

# リソースを複数作る場合は for_each を使う
# for_each を使うケース

dynamic "tag" {
  for_each = {
    # 大文字に変換したい場合、for_each はリソースを修飾しているので、for を使う
    for key, value in var.custom_tags : key => value
    key => upper(value)
    if key != "Name"
  }
  content {
    key = tag.key
    value = tag.value
    propagate_at_launch = true
  }
}
```

## 文字列ディレクティブの空白・改行対応

- p167
