# wedding

모바일 청첩장 정적 사이트입니다.

## GitHub Pages

1. GitHub에서 `wedding` 저장소를 생성합니다.
2. 이 폴더에서 원격 저장소를 연결합니다.
3. `main` 브랜치를 push합니다.
4. GitHub 저장소의 `Settings > Pages`에서 `Deploy from a branch`, `main`, `/root`를 선택합니다.

배포 후 기본 주소는 아래와 같습니다.

```text
https://tootouch.github.io/wedding/
```

## 참석 의사와 축하 메시지 Google Sheets 연결

참석 의사와 축하 메시지는 먼저 브라우저에 백업 저장되고, `script.js`의 `rsvpEndpoint` 값이 설정되면 Google Sheets로도 전송됩니다.

1. Google Sheets에서 새 스프레드시트를 만듭니다.
2. 메뉴에서 `확장 프로그램 > Apps Script`를 엽니다.
3. 이 저장소의 `google-apps-script-rsvp.gs` 내용을 Apps Script 편집기에 붙여넣습니다.
4. `setup` 함수를 한 번 실행하고 권한을 승인합니다.
5. `배포 > 새 배포 > 웹 앱`을 선택합니다.
6. 설정은 `실행 권한: 나`, `액세스 권한: 모든 사용자`로 둡니다.
7. 배포 후 생성되는 Web app URL을 복사합니다. 주소는 보통 `/exec`로 끝납니다.
8. `script.js`에서 아래 값을 복사한 URL로 바꿉니다.

```js
rsvpEndpoint: "https://script.google.com/macros/s/.../exec",
```

URL을 넣은 뒤 다시 commit/push하면 GitHub Pages의 참석 의사 제출이 `RSVP` 시트에 기록됩니다.
축하 메시지는 `GUESTBOOK` 시트에 기록되며, 작성자가 입력한 숫자 4자리 비밀번호로 삭제할 수 있습니다.

Apps Script 내용을 수정한 뒤에는 기존 배포도 새 버전으로 다시 배포해야 합니다.
`배포 > 배포 관리 > 수정 > 새 버전 > 배포`를 선택하면 기존 `/exec` URL을 그대로 사용할 수 있습니다.
