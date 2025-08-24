

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

# 4) 디코딩된 서비스키 입력
service_key <- ***blanks***
  
#아래는 인코딩
  #"***blanks***"

# 최신 엔드포인트 (HTTPS, 443)
base_url <- "***blanks***e" # 새로 추가!

# 03-2 요청 목록 생성: 자료 요청 방법

# 1) 요청 목록 만들기 
url_list <- list() # 빈 리스트 만들기
cnt <- 0 # 반복문 제어 변수 초깃값 설정

# 2)요청 목록 채우기
for ( i in 1:nrow(loc)){ # 외부 반복: 25개 자치구
  for (j in 1:length(datelist)){ # 내부 반복: 12개월
    cnt <- cnt+1 # 반복 누적 세기
    
    #---# 요청 목록 채우기(25x12 = 300)
    url_list[cnt] <- paste0(base_url, # 엔드포인트
                            "?LAWD_CD=", loc[i,1], # 지역 코드
                            "&DEAL_YMD=", datelist[j], # 수집 월
                            "&numOfRows=", 100, # 한 페이지 결과 수
                            "&serviceKey=", service_key) #인증키
  }
  Sys.sleep(0.1) # 0.1초간 멈춤
  msg<- paste0("[", i, "/", nrow(loc), "]  ", loc[i,3], "
               의 크롤링 목록이 생성됨 => 총 [", cnt,"] 건") # 알림메세지
  cat(msg,"\n\n")
}

# 3) 요청 목록 동작 확인
length(url_list) # 요청 목록 개수 확인
browseURL(paste0(url_list[1])) # 정상 동작 확인(웹 브라우저 실행)

# 03-3 크롤러 제작: 자동으로 자료 수집하기
# Ctrl + Shift + C로 전체 주석
# # 1) 임시 저장 리스트 생성 
# install.packages("XML")
# install.packages("data.table")
# install.packages("stringr")
# 
# library(XML)
# library(data.table)
# library(stringr)
# 
# raw_data <- list() # xml 임시 저장소
# root_Node <- list() # 거래 내역 추출 임시 저장소
# total <- list() # 거래 내역 정리 임시 저장소
# dir.create("02_raw_data") # 새로운 폴더 만들기
# 
# # 2) URL 요청 - XML 응답
# for(i in 1:length(url_list)){
#   raw_data[[i]] <- xmlTreeParse(url_list[i], useInternalNodes=TRUE,
#                                 encoding = "utf-8") # 결과저장
#   root_Node[[i]] <- xmlRoot(raw_data[[i]]) # xmlRoot로 루트 노드 이하 추출
# }
# 
# # 3) 전체 거래 건수 확인
# items <- root_Node[[i]][[2]][['items']] # 전체 거래 내역(items) 추출
# size <- xmlSize(items) # 전체 거래 건수 확인
# 
# # 4) 개별 거래 내역 추출하기
# item <- list() #전체 거래 내역(items) 저장 임시 리스트 생성
# item_temp_dt <- data.table() # 세부 거래 내역(item) 저장 임시 테이블 생성
# Sys.sleep(.1) # 0.1초 멈춤
# 
# for(m in 1:size){
#   #---# 세부 거래 내역 분리
#   item_temp <- xmlSApply(items[[m]], xmlValue) # xml을 데이터로만
#   item_temp_dt <- data.table(year = item_temp[4], # 거래 연도
#                              month = item_temp[7], # 거래 월
#                              day = item_temp[8], # 거래 일
#                              price = item_temp[1], # 거래 금액
#                              code = item_temp[12], # 지역코드
#                              dong_nm = item_temp[5], # 법정동
#                              jibun = item_temp[11], # 지번
#                              con_year = item_temp[3], # 건축 연도
#                              apt_nm = item_temp[6], # 아파트 이름
#                              area = item_temp[9], # 전용 면적
#                              floor = item_temp[13] # 층수
#                              ) 
#   item[[m]]<- item_temp_dt  # 분리된 거래 내역 순서대로 저장
# 
# 
# apt_bind <- rbindlist(item) # 지금까지 쌓은 item[[1]],item[[2]]를 하나의 큰 테이블로 통합저장
# 
# # 5) 응답 내역 저장
# region_nm <- subset(loc, code== str_sub(url_list[i], 115, 119))$addr_1 # 지역명
# month <- str_sub(url_list[i], 130, 135) # 연월(YYYYMM)
# path <- as.character(paste0("./02_raw_data/", region_nm, "_", month, ".csv"))
# write.csv(apt_bind, path) # csv 파일로 저장
# msg <- paste0("[", i, "/", length(url_list),
#               "] 수집한 데이터를 [", path,"]에 저장합니다.") # 알람 메세지
# cat(msg, "\n\n")
# 
# } # 바깥쪽 반복문 종료

# 03-3 크롤러 제작: 자동으로 자료 수집하기 (httr + xml2 + 디버그 버전)

library(httr)
library(xml2)
library(data.table)
library(stringr)

# 출력 폴더 준비
dir.create("02_raw_data", showWarnings = FALSE)

for (i in seq_along(url_list)) {
  u <- as.character(url_list[[i]])   # 리스트에서 URL 문자열 추출 (반드시 [[i]])
  
  # 1) HTTP 요청
  resp <- tryCatch(GET(u), error = function(e) NULL)
  if (is.null(resp)) { 
    cat("[", i, "] HTTP 실패\n", sep = ""); 
    next 
  }
  if (status_code(resp) != 200) { 
    cat("[", i, "] HTTP status:", status_code(resp), "\n"); 
    next 
  }
  
  # 2) XML 파싱
  txt <- content(resp, "text", encoding = "UTF-8")
  doc <- tryCatch(read_xml(txt), error = function(e) NULL)
  if (is.null(doc)) { 
    cat("[", i, "] XML 파싱 실패\n"); 
    next 
  }
  
  # 3) 결과코드/메시지 디버그 출력 (정상: 00 또는 000)
  rc <- xml_text(xml_find_first(doc, ".//resultCode"))
  rm <- xml_text(xml_find_first(doc, ".//resultMsg"))
  cat("[", i, "] resultCode:", rc, " / resultMsg:", rm, "\n")
  
  if (!(rc %in% c("00", "000"))) {
    # 비정상 응답이면 저장 스킵
    next
  }
  
  # 4) 아이템 추출 (실제 응답은 영문 태그임!)
  items <- xml_find_all(doc, ".//items/item")
  n <- length(items)
  cat("    items:", n, "\n")
  if (n == 0) {
    # 진짜 비었는지 미리보기
    cat("    preview: ", substr(txt, 1, 180), "\n", sep = "")
    next
  }
  
  # 5) 한 건이라도 있으면 영문 태그로 매핑하여 테이블화
  getf <- function(node, tag) xml_text(xml_find_first(node, paste0(".//", tag)))
  dt <- rbindlist(lapply(items, function(node) data.table(
    year     = getf(node, "dealYear"),
    month    = getf(node, "dealMonth"),
    day      = getf(node, "dealDay"),
    price    = getf(node, "dealAmount"),
    code     = getf(node, "sggCd"),
    dong_nm  = getf(node, "umdNm"),
    jibun    = getf(node, "jibun"),
    con_year = getf(node, "buildYear"),
    apt_nm   = getf(node, "aptNm"),
    area     = getf(node, "excluUseAr"),
    floor    = getf(node, "floor")
  )), fill = TRUE)
  
  # (선택) 값 정리: 가격에서 콤마 제거 등
  if ("price" %in% names(dt)) {
    dt[, price := as.numeric(gsub(",", "", price))]
  }
  if ("area" %in% names(dt)) {
    dt[, area := as.numeric(area)]
  }
  if ("floor" %in% names(dt)) {
    suppressWarnings(dt[, floor := as.integer(floor)])
  }
  if ("con_year" %in% names(dt)) {
    suppressWarnings(dt[, con_year := as.integer(con_year)])
  }
  suppressWarnings(dt[, year := as.integer(year)])
  suppressWarnings(dt[, month := as.integer(month)])
  suppressWarnings(dt[, day := as.integer(day)])
  
  # 6) 파일명: URL 쿼리에서 안전 추출 (고정 인덱스 사용 금지)
  qstr <- strsplit(u, "\\?", 2)[[1]][2]
  qs   <- strsplit(qstr, "&")[[1]]
  get_q <- function(k) sub(paste0("^", k, "="), "", qs[grepl(paste0("^", k, "="), qs)])
  lawd <- get_q("LAWD_CD")
  ym   <- get_q("DEAL_YMD")
  
  # 지역명 매핑 (loc에 code/addr_1 컬럼 있다고 가정)
  region_nm <- tryCatch(subset(loc, code == lawd)$addr_1, error = function(e) lawd)
  if (length(region_nm) == 0) region_nm <- lawd
  
  # 7) 저장
  out <- file.path("02_raw_data", paste0(region_nm, "_", ym, ".csv"))
  fwrite(dt, out)
  cat("    저장:", out, "(", nrow(dt), "행)\n", sep = "")
  
  Sys.sleep(0.08)  # 너무 빠른 연속호출 방지 (API 예의)
}




# 03-4 자료 정리: 자료 통합하기
# 1) csv 파일 통합하기
setwd(dirname(rstudioapi::getSourceEditorContext()$path)) # 작업 폴더 설정 

# 수정본본
files <- list.files("02_raw_data", pattern="\\.csv$", full.names=TRUE)
if (length(files) == 0) {
  cat("저장된 CSV가 없습니다. (앞 단계에서 XML 파싱 실패)\n")
} else {
  apt_price <- data.table::rbindlist(lapply(files, fread), fill=TRUE)
  tail(apt_price, 2)
}


install.packages("plyr")
library(plyr)
apt_price <- ldply(as.list(paste0("./02_raw_data/", files)), read.csv) # 결합
tail(apt_price, 2)# 확인























