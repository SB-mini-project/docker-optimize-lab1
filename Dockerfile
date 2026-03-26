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