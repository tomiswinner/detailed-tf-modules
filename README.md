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

## launch configuration に asg の名前を依存させたゼロダウンタイムデプロイについて

- tf apply をした場合

1. 新しい asg DOG が作成され、ALB に登録されてヘルスチェックが開始
2. min_elb_capacity のヘルスチェック成功まで、新しい asg DOG のデプロイ完了とはならない
3. 新しい asg DOG のデプロイ完了後、古い asg CAT の削除が開始

確かにゼロダウンタイムデプロイではある、古い機能と新しい機能が混在する感じになるのか、完璧とは言えなそうだな

ただ、それっていわゆる Rolling Update っていうわけか、全然使い所あるな

しかも、↑ は現在非推奨かも、今はネイティブのソリューションがあるっぽい、それに min_size とかスケジューリングしてたらデプロイ時にリセットされちゃう

## tf のつまづきポイント

1. count や for_each はデプロイの前に実行される（plan 時）から、リソース参照ができない条件分岐とかでも注意が必要か
2. ネイティブソリューションがあるので、ゼロダウンタイムデプロイは不要(instance_refresh を使う)
3. 外部リソースは terraform import する
4. terraform state mv ではなく movd を使う
