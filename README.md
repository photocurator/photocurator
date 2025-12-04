# 📸 Photocurator (포토큐레이터)

> AI 기반 사진 관리 및 분석 서비스  
> "여행은 즐겁게, 사진 선별은 포토큐레이터가."

![Photocurator Mockup](/assets/mockup.png)

## 📌 프로젝트 배경 및 목적

### 문제 정의: "사진 정리의 고통"

특별한 이벤트나 여행 후 수백 장의 사진을 정리하는 것은 시간이 많이 소요되고 번거로운 작업입니다. 
- **55%**의 사용자가 이벤트 후 50장 이상의 사진을 찍음
- **80%**의 사용자가 사진 선별 작업이 귀찮거나 포기한 경험이 있음
- 평균 **10분 이상**이 사진 정리에 소요됨

### Why Now?

1. **사진 시장 폭발적 증가**: 전 세계 사진 시장 규모 2025년 1,500억 달러 돌파, 연평균 4~9% 성장세
2. **사진 취미 증가**: 카메라 출하량 7년 만에 반등(+15%), 미러리스 점유율 83.7%, 렌즈 가격 200% 상승
3. **이미지 AI 서비스 대중화**: 전 세계 AI 이미지 생성 시장 4억 달러, 생성형 AI 시장 46.6% 성장률

### GOAL

**AI를 활용한 간편하고 정확한 사진 정리!**

## ✨ 주요 기능

포토큐레이터는 사용자가 사진을 손쉽게 정리하고, 베스트 샷을 추천받으며, 원하는 사진을 빠르게 찾을 수 있도록 다음과 같은 세 가지 핵심 기능을 제공합니다.

#### 1. 사진 정리 (Photo Organization)
- 사진 업로드 및 분류
- EXIF 메타데이터를 활용하여 같은 날·같은 장소에서 찍은 사진들을 그룹화

#### 2. 베스트 샷 추천 (Best Shot Recommendation)
- AI 모델이 각 사진을 분석하여 사진 품질 점수(Image Quality Score) 산출
- 점수를 기준으로 상위 N장의 사진을 베스트 샷으로 추천

#### 3. 스마트 검색 (Smart Search)
- AI 캡셔닝으로 사진 속 인물, 사물, 장소 등을 태깅
- "강아지", "야경", "서울 여행" 등의 자연어로 직관적인 검색 가능
- EXIF 정보(카메라, 렌즈, ISO 등) 기반의 고급 필터링 지원

## 🛠️ 기술 스택

![Architecture Diagram](/assets/arch.png)

### Core stack

- Frontend: Flutter
- Backend: FastAPI, Hono, Drizzle ORM, Bun
- Database: PostgreSQL
- AI Processing: Celery, PyTorch, Ultralytics, Pillow, OpenCV, ImageHash, Timm, PyIQA

### AI Processing Pipeline
![AI Processing Pipeline](/assets/img.png)


## 👥 팀원 소개 및 역할

---

### 이가은
[![GitHub](https://img.shields.io/badge/GitHub-Ssamssamukja-181717?style=flat-square&logo=github)](https://github.com/Ssamssamukja)

**Role**: Frontend Development
- 프론트 프로젝트 구조 및 디자인 시스템 구축
- 프론트 기능 구현 및 API 연결

**Tech Stack Used**: `Flutter` `Figma`

---

### 이든솔
[![GitHub](https://img.shields.io/badge/GitHub-Party4Bread-181717?style=flat-square&logo=github)](https://github.com/Party4Bread)

**Role**: Product Owner & Backend & AI Pipeline
- Product 기획
- UX 기획(사용자 흐름 설계) 및 리서치
- Backend API 구현
- AI processing pipeline 구현

**Tech Stack Used**: `fastapi` `hono` `postgresql` `Flutter`

---

### 이민서 
[![GitHub](https://img.shields.io/badge/GitHub-leelee001-181717?style=flat-square&logo=github)](https://github.com/leelee001)

**Role**: UI/UX Design & Frontend
- UI/UX 기획 및 디자인
- 사용자 흐름 기반의 전체 화면 구조 설계 및 Figma 와이어프레임·프로토타입 제작
- 디자인 시스템(컬러, 타이포그래피, 컴포넌트 패턴) 구축
- 주요 UI 컴포넌트 및 페이지의 Frontend 구현 및 API 연결

**Tech Stack Used**: `Flutter` `Figma`


---

## 🎯 협업 방식

### Backlog Marketplace
Backlog에 해야 할 것, 하면 좋은 것을 적고, 현재 처리가 가능한 사람이 해당 Backlog를 입찰하여 진행합니다.

### Shared Channel
모두가 하나의 채널(Discord)을 사용하여 소통하고 자료 공유는 Notion으로, 레포지토리는 monorepo로 관리합니다. No 1 on 1!

### Weekly Meeting
매주 정기 미팅으로 진행 상황을 공유하고, Marketplace를 점검합니다.

---

## 📂 프로젝트 구조

```
.
├── backend              # Backend API Server (Hono, Drizzle ORM)
│   ├── drizzle          # DB Migrations
│   ├── src
│   │   ├── db           # Database Schema & Connection
│   │   ├── lib          # Shared Libraries (Auth, etc.)
│   │   └── routes       # API Routes
│   └── storage          # Local Storage for Images
├── backend-py           # AI Processing Server (FastAPI)
│   ├── e2e-test         # End-to-End Tests
│   ├── src
│   │   ├── tasks        # Celery Tasks (AI Processing)
│   │   ├── db.py        # Database Connection
│   │   └── statistics.py
│   ├── server.py        # FastAPI Entrypoint
│   └── worker.py        # Celery Worker Entrypoint
└── frontend-mobile      # Mobile App (Flutter)
    ├── assets           # Fonts & Icons
    ├── lib
    │   ├── common       # Shared Components & Utils
    │   ├── features     # Feature-based Modules
    │   ├── provider     # State Management
    │   └── route        # Navigation
    └── test             # Tests
```

