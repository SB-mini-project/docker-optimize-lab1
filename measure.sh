#!/bin/bash

# 반복 횟수 및 대기 시간 설정
ITERATIONS=5
SLEEP_TIME=5

# 이미지 이름 설정
IMAGE_NAME="perf-test-image"

# 로그 파일 설정
LOG_FILE="build_times.log"
ERROR_LOG="build_error.log"

# 결과 저장 배열 초기화
RESULTS=()

echo "--- 빌드 성능 측정 시작 ($ITERATIONS 회 반복) ---"
echo "시작 시간: $(date)" > $LOG_FILE

for i in $(seq 1 $ITERATIONS); do
    echo "[$i/$ITERATIONS] 캐시 및 이미지 제거 중..."

    # 캐시 및 이미지 제거
    docker builder prune -a -f > /dev/null 2>&1
    docker rmi -f $IMAGE_NAME > /dev/null 2>&1

    # 빌드 시작 전 대기
    sleep $SLEEP_TIME

    echo "[$i/$ITERATIONS] 빌드 시작..."

    # 시간 측정 시작
    START_TIME=$(date +%s)

    # 빌드 실행
    if ! docker build --no-cache -t $IMAGE_NAME . > /dev/null 2> "$ERROR_LOG"; then
        echo "❌ [${i}/${ITERATIONS}] 빌드 실패!"
        exit 1
    fi

    END_TIME=$(date +%s)

    # 소요 시간 계산
    DURATION=$((END_TIME - START_TIME))
    RESULTS+=("$DURATION")

    echo "✅ [$i/$ITERATIONS] 완료: ${DURATION}초"
    echo "$DURATION" >> $LOG_FILE
done

echo "--------------------------------------"
echo "측정 완료! 결과 요약:"

# 평균 계산
SUM=0
for r in "${RESULTS[@]}"; do
  SUM=$((SUM + r))
done
AVG=$(( SUM / ITERATIONS ))

# 결과 출력
echo "Total: $SUM 초"
echo "Average: $AVG 초"