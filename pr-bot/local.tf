locals {
  # 프로젝트 공통 prefix
  name = "gitbot"

  # Step Lambda 이름 규칙
  # → IAM에서 prefix wildcard로 제어하기 위함
  steps = {
    lint       = "${local.name}-step-lint"
    test       = "${local.name}-step-test"
    dependency = "${local.name}-step-dependency"
    review     = "${local.name}-step-review"
  }

  # Lambda 소스 디렉토리 매핑
  # archive_file에서 사용
  step_source_dirs = {
    lint       = "lint"
    test       = "test"
    dependency = "dependency"
    review     = "review"
  }
}