

# 저자 깃: https://github.com/cmman75/Open_data_R_with_Shiny
# 03-1 크롤링 준비

# 1) 작업 폴더 설정
install.packages("rstudioapi") # rstudioapi 설치
setwd(dirname(rstudioapi::getSourceEditorContext()$path)) #작업폴더설정
getwd() # 작업 폴더 확인

# 2) 수집 대상 지역 설정
loc <- read.csv("./01_code/sigun_code/sigun_code.csv", fileEncoding ="UTF-8") # 지역코드 
loc$code <- as.character(loc$code) # 행정구역명 문자 변환
head(loc,2)

# 3) 데이터 수집 기간 설정
datelist <- seq(from = as.Date('2021-01-01'), # 시작
                to = as.Date('2021-12-31'), # 끝
                by = '1 month') # 단위

datelist <- format(datelist, format='%Y%m') # 형식변환(YYYY-MM-DD => YYYYMM)
datelist[1:3] # 확인

# 4) 인증키 입력
service_key <- ***blank***

# 03-2 요청 목록 생성: 자료 요청 방법

# 1) 요청 목록 만들기 
url_list <- list() # 빈 리스트 만들기
cnt <- 0 # 반복문 제어 변수 초깃값 설정

# 2)요청 목록 채우기
for ( i in 1:nrow(loc)){ # 외부 반복: 25개 자치구
  for (j in 1:length(datelist)){ # 내부 반복: 12개월
    cnt <- cnt+1 # 반복 누적 세기
    
    #---# 요청 목록 채우기(25x12 = 300)
    url_list[cnt] <- paste0("http://openapi.molit.go.kr:8081/OpenAPI_ToolInstallPackage/service/rest/RTMSOBJSvc/getRTMSDataSvcAptTrade?",
                            "LAWD_CD=", loc[i,1], # 지역 코드
                            "&DEAL_YMD=", datelist[j], # 수집 월
                            "&numOfRows=", 100, # 한 페이지 결과 수
                            "&serviceKey=", service_key) #인증키
  }
  Sys.sleep(0.1) # 0.1초간 멈춤춤
  msg<- paste0("[", i, "/", nrow(loc), "]  ", loc[i,3], "
               의 크롤링 목록이 생성됨 => 총 [", cnt,"] 건") # 알림메세지
  cat(msg,"\n\n")
}

# 3) 요청 목록 동작 확인
length(url_list) # 요청 목록 개수 확인
browseURL(paste0(url_list[1])) # 정상 동작 확인(웹 브라우저 실행)

# 03-3 크롤러 제작: 자동으로 자료 수집하기

# 1) 임시 저장 리스트 생성 
install.packages("XML")
install.packages("data.table")
install.packages("stringr")

library(XML)
library(data.table)
library(stringr)

raw_data <- list() # xml 임시 저장소
root_Node <- list() # 거래 내역 추출 임시 저장소
total <- list() # 거래 내역 정리 임시 저장소
dir.create("02_raw_data") # 새로운 폴더 만들기

# 2) URL 요청 - XML 응답
for(i in 1:length(url_list)){
  raw_data[[i]] <- xmlTreeParse(url_list[i], useInternalNodes=TRUE,
                                encoding = "utf-8") # 결과저장
  root_Node[[i]] <- xmlRoot(raw_data[[i]]) # xmlRoot로 루트 노드 이하 추출
}

# 3) 전체 거래 건수 확인
items <- root_Node[[i]][[2]][['items']] # 전체 거래 내역(items) 추출
size <- xmlSize(items) # 전체 거래 건수 확인

# 4) 개별 거래 내역 추출하기
item <- list() #전체 거래 내역(items) 저장 임시 리스트 생성
item_temp_dt <- data.table() # 세부 거래 내역(item) 저장 임시 테이블 생성
Sys.sleep(.1) # 0.1초 멈춤

for(m in 1:size){
  #---# 세부 거래 내역 분리
  item_temp <- xmlSApply(items[[m]], xmlValue) # xml을 데이터로만
  item_temp_dt <- data.table(year = item_temp[4], # 거래 연도
                             month = item_temp[7], # 거래 월
                             day = item_temp[8], # 거래 일
                             price = item_temp[1], # 거래 금액
                             code = item_temp[12], # 지역코드
                             dong_nm = item_temp[5], # 법정동
                             jibun = item_temp[11], # 지번
                             con_year = item_temp[3], # 건축 연도
                             apt_nm = item_temp[6], # 아파트 이름
                             area = item_temp[9], # 전용 면적
                             floor = item_temp[13] # 층수
                             ) 
  item[[m]]<- item_temp_dt  # 분리된 거래 내역 순서대로 저장


apt_bind <- rbindlist(item) # 지금까지 쌓은 item[[1]],item[[2]]를 하나의 큰 테이블로 통합저장

# 5) 응답 내역 저장
region_nm <- subset(loc, code== str_sub(url_list[i], 115, 119))$addr_1 # 지역명
month <- str_sub(url_list[i], 130, 135) # 연월(YYYYMM)
path <- as.character(paste0("./02_raw_data/", region_nm, "_", month, ".csv"))
write.csv(apt_bind, path) # csv 파일로 저장
msg <- paste0("[", i, "/", length(url_list),
              "] 수집한 데이터를 [", path,"]에 저장합니다.") # 알람 메세지
cat(msg, "\n\n")

} # 바깥쪽 반복문 종료


# 03-4 자료 정리: 자료 통합하기
# 1) csv 파일 통합하기
setwd(dirname(rstudioapi::getSourceEditorContext()$path)) # 작업 폴더 설정
files <- dir("./02_raw_data") # 폴더 내 모든 파일명 읽기
install.packages("plyr")
library(plyr)
apt_price <- ldply(as.list(paste0("./02_raw_data/", files)), read.csv) # 결합

