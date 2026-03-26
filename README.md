# docker-optimize-lab1
도커 이미지 최적화 학습 및 정리 레포지토리

<br>

## 프로젝트 개요

> 이미지 크기와 빌드 시간에 영향을 주는 안티 패턴을 의도적으로 적용해 보고, 최적화된 Dockerfile과의 성능 차이(용량 및 시간)를 정량적으로 비교 분석
> 

💡 단순한 개선이 아니라 **비효율 → 원인 분석 → 최적화 → 결과 검증**의 흐름을 통해 Docker 레이어 구조와 캐싱 전략이 실제 성능에 미치는 영향을 확인하는 데 목적

<br>

## 실습 방식

Docker 이미지 최적화의 필요성을 검증하기 위해, 의도적으로 Anti-pattern을 적용한 비효율적인 Dockerfile을 먼저 설계

이후 동일한 Python 애플리케이션(**Docker-2-Notion (D2N))**을 기준으로

1. 비효율적인 Dockerfile (Anti-pattern 적용)

2. 최적화된 Dockerfile

두 가지 환경을 구성한 뒤, **빌드 시간과 이미지 용량을 반복 측정하여 평균값을 비교**

<br>

## 실습 수행 절차

### 1. **성능 측정 자동화 환경 구축**
- Shell Script 작성하여 반복적인 빌드 & 캐시 삭제 과정 수행
- **Shell Script 주요 로직**
    - 5회 반복 빌드
    - 빌드 전 `docker builder prune -a`를 통한 캐시 강제 삭제
    - 기존 이미지 삭제
    - `date` 명령어를 활용한 소요 시간 기록 및 평균값 계산

### 2. **비효율적 Dockerfile 설계 - 비교군 생성**
- 최적화된 기존 코드의 장점을 제거하여 성능 저하 유도
- 무거운 베이스 이미지 사용
    - slim 버전이 아닌 전체 패키지가 포함된 이미지 사용
- 레이어 캐싱 미적용
    - 소스 코드 복사 파트를 상단 배치하여 의존성 설치가 매번 재실행되도록 설정
- 레이어 비대화
    - `RUN` 명령어를 분리하여 불필요한 레이어 생성
- 단일 스테이지 빌드
    - 빌드 도구와 실행 환경을 분리하지 않음
### 3. **성능 측적 수행**
- 작성한 스크립트를 실행하여 최적화 전/후 결과 데이터 확보
- **측정 항목**
    - 빌드당 소요 시간(초)
    - 총 빌드 시간
    - 평균 빌드 시간
    - 최종 이미지 용량(MB)
### 4. **결과 분석 및 시각화**

<br>

---
<br>

## 최적화 성능 측정

### Dockerfile

**최적화 전**

```docker
# 풀 버전 베이스 이미지 사용
FROM python:3.13

# 환경 변수 설정
ENV TZ=Asia/Seoul
ENV LOG_LEVEL=INFO

# 작업 디렉토리 설정
WORKDIR /app

# 모든 작업 파일 복사
COPY . .

# 의존성 패키지 및 빌드 도구 설치
RUN apt-get update
RUN apt-get install -y gcc build-essential libffi-dev git vim curl 

# 파이썬 패키지 설치
RUN pip install -r requirements.txt
RUN pip install pyinstaller

# 애플리케이션 빌드
RUN pyinstaller --onefile --name Docker-2-Notion --clean main.py

# 볼륨 설정 (로그, 설정, 데이터 저장용)
VOLUME ["/app/logs", "/app/config", "/app/data"]

# 컨테이너 실행 시 애플리케이션 실행
CMD ["./dist/Docker-2-Notion"]
```

<br>

**최적화 후 (기존 Dockerfile)**

```docker
# 1단계: 빌드 환경
FROM python:3.13-slim-trixie AS builder

WORKDIR /app

# 빌드 의존성 설치
RUN apt-get update && apt-get install -y gcc build-essential libffi-dev && rm -rf /var/lib/apt/lists/*

# 패키지 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install pyinstaller

# 소스 코드 전체 복사 및 빌드
COPY . .
RUN pyinstaller --onefile --name Docker-2-Notion --clean main.py

# 2단계: 실행 환경
FROM debian:trixie-slim

WORKDIR /app

# 런타임 의존성 설치 (타임존, 인증서 등)
RUN apt-get update && apt-get install -y ca-certificates tzdata && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/dist/Docker-2-Notion .

ENV TZ=Asia/Seoul
ENV LOG_LEVEL=INFO

# 로그, 설정, 캐시 데이터는 컨테이너 외부에서 관리하도록 볼륨으로 설정
# 실행 시: -v ./logs:/app/logs -v ./config:/app/config -v ./data:/app/data
VOLUME ["/app/logs", "/app/config", "/app/data"]

CMD ["./Docker-2-Notion"]
```

<br>

### 성능 결과

**최적화 전**

```
--- 빌드 성능 측정 시작 (5 회 반복) ---
[1/5] 캐시 및 이미지 제거 중...
[1/5] 빌드 시작...
✅ [1/5] 완료: 47초
[2/5] 캐시 및 이미지 제거 중...
[2/5] 빌드 시작...
✅ [2/5] 완료: 49초
[3/5] 캐시 및 이미지 제거 중...
[3/5] 빌드 시작...
✅ [3/5] 완료: 50초
[4/5] 캐시 및 이미지 제거 중...
[4/5] 빌드 시작...
✅ [4/5] 완료: 48초
[5/5] 캐시 및 이미지 제거 중...
[5/5] 빌드 시작...
✅ [5/5] 완료: 47초
--------------------------------------
측정 완료! 결과 요약:
Total: 241 초
Average: 48 초
```

**최적화 후 (기존 파일)**

```
--- 빌드 성능 측정 시작 (5 회 반복) ---
[1/5] 캐시 및 이미지 제거 중...
[1/5] 빌드 시작...
✅ [1/5] 완료: 31초
[2/5] 캐시 및 이미지 제거 중...
[2/5] 빌드 시작...
✅ [2/5] 완료: 31초
[3/5] 캐시 및 이미지 제거 중...
[3/5] 빌드 시작...
✅ [3/5] 완료: 32초
[4/5] 캐시 및 이미지 제거 중...
[4/5] 빌드 시작...
✅ [4/5] 완료: 31초
[5/5] 캐시 및 이미지 제거 중...
[5/5] 빌드 시작...
✅ [5/5] 완료: 30초
--------------------------------------
측정 완료! 결과 요약:
Total: 155 초
Average: 31 초
```

```
최적화 전 - 1,380 MB
최적화 후 - 101 MB
```
<br>

---

<br>

### **결론**

<aside>

| **항목** | **최적화 전** | **최적화 후** | **개선 효과** |
| --- | --- | --- | --- |
| **빌드 총 시간** | 241 초 | 155 초  | 약 36% 감소 |
| **평균 빌드 시간** | 48 초 | 31 초 | 약 35% 감소 |
| **이미지 크기** | 1,380 MB | 101 MB | 약 92% 감소 |

</aside>
