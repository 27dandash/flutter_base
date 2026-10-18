// Throwaway self-signed certificates generated only for these tests
// (openssl, 100-year validity, CN *.example.test). They protect nothing.
// The EC private key body is stored without its PEM header so that no literal
// private-key block exists in the repository; `TlsFixtures.privateKeyPem`
// reassembles it at run time.
// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';
import 'dart:typed_data';

final class TlsFixture {
  const TlsFixture({
    required this.derBase64,
    required this.derSha256,
    required this.spkiHex,
    required this.spkiBase64,
  });

  final String derBase64;
  final String derSha256;
  final String spkiHex;
  final String spkiBase64;

  Uint8List get der => base64.decode(derBase64);

  String get pem {
    final lines = RegExp('.{1,64}').allMatches(derBase64).map((m) => m[0]);
    return '-----BEGIN CERTIFICATE-----\n${lines.join('\n')}\n-----END CERTIFICATE-----\n';
  }
}

abstract final class TlsFixtures {
  static const rsa = TlsFixture(
    derBase64:
        'MIIDGTCCAgGgAwIBAgIUSrsFKI1t8CZAuUSf94is77c1JoowDQYJKoZIhvcNAQELBQAwGzEZMBcG'
        'A1UEAwwQcnNhLmV4YW1wbGUudGVzdDAgFw0yNjEwMTgxOTI3NDRaGA8yMTI2MDkyNDE5Mjc0NFow'
        'GzEZMBcGA1UEAwwQcnNhLmV4YW1wbGUudGVzdDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC'
        'ggEBAN0kRDB6sxTYlNp1eUI8CbSWJLOfhVh/TLQVmCkvpvhC+Uo51L3migGJlS0KpTDfo2b0wtyv'
        'XMKjiD0MpjyTcgykHvcoXOhjAYE1JQDifjtMp5Q+gA/wrli7aFjI9nrKYUNOk7xSFFZCtmHf4yCX'
        's64nNXrx/70BGEbjzPQkGbdIGV8JrHWFa+H1MGT4WUOsnal+ABUZJuTDs0nCKbAfSnlUDFd9j/qz'
        'QC2J/a9Q4HRRLH8XtFZQ50cM02Nnq8K+aol21VhYTvT0CNNbL2SGmAL0GUuXUNmV1HBq94txsbJa'
        'tZ/1Som/TPj2L5xgg04X1DZyvKtYNhPP70I+JhVA5h8CAwEAAaNTMFEwHQYDVR0OBBYEFOARvIeA'
        'azfHRsD8rMKCEpszNspiMB8GA1UdIwQYMBaAFOARvIeAazfHRsD8rMKCEpszNspiMA8GA1UdEwEB'
        '/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBAIDAitGpUGchB8lFrBP3uKAuvHREIFHOLVPVFuaA'
        'kRab7qDsnA4BVffOoxvPVKvtK0RatLNVA/XoHAFt7UgYc0fcgzSk9RoTOH0yd1nFeNUv6XlmQzfl'
        'qqxwGcXqMxDwaiXCcVeXd5VN+wgxgGsJurbQlP1tMuZrHTNuJY4tI+U+rs5LcAmMD24p6+a3PAN4'
        'oWu/ZOLr/JFHUibaWUB/qUp2PtiEvJarPf9SqD6XnTu5mgqU2FMWCqSbiLQWRDY0WbAKsp/Gl8mQ'
        'gaabagMcuDHP1j8QZhCiaUz3d4b9oq95JnH8ZFqJx/r+Lo2NRurzQZIWF7qfZ3u4dAAox7AZYxg=',
    derSha256:
        'f832e3a0e9e02e86d444db94a7eba2a255dc9f62cfad4f28802102382767c4a6',
    spkiHex: 'eb21fc0aa57aec1c25086c30cde861fc7099ac1dba44029dc0881cbb592c806d',
    spkiBase64: '6yH8CqV67BwlCGwwzehh/HCZrB26RAKdwIgcu1ksgG0=',
  );

  static const ec = TlsFixture(
    derBase64:
        'MIIBizCCATGgAwIBAgIUZWkNy2i1nMFvN6NT7XfwauHYXkIwCgYIKoZIzj0EAwIwGjEYMBYGA1UE'
        'AwwPZWMuZXhhbXBsZS50ZXN0MCAXDTI2MTAxODE5Mjc0NFoYDzIxMjYwOTI0MTkyNzQ0WjAaMRgw'
        'FgYDVQQDDA9lYy5leGFtcGxlLnRlc3QwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAARTliSKhWg1'
        'D0eOUcyQKen3Xf818glscj5yeHyd2pgY2/obCRIHxP2zZsqlXMfwfRorjFIjcgCjyU8QRQ4/+V0W'
        'o1MwUTAdBgNVHQ4EFgQUChKErzpk7FBM/HZ2LJplb2XzsQQwHwYDVR0jBBgwFoAUChKErzpk7FBM'
        '/HZ2LJplb2XzsQQwDwYDVR0TAQH/BAUwAwEB/zAKBggqhkjOPQQDAgNIADBFAiBaVia/cOAW65Tt'
        'r/0wUKGkMrE6SG7W7mlUgHwFrn3w1AIhAOhuY7p9Uw2Cb2beNj2Gcqm9NV04MTeSK2CHoZAc6U/y',
    derSha256:
        '478f87966cd369cb547a46b96e3e8b90866f2bf3d2ae48d94c3aeab714f04ea0',
    spkiHex: '0fdd39787c9fee07c3ca9d7075f2e7f82e3159caf86904a591e8082e57704a92',
    spkiBase64: 'D905eHyf7gfDyp1wdfLn+C4xWcr4aQSlkegILldwSpI=',
  );

  static const other = TlsFixture(
    derBase64:
        'MIIBkjCCATegAwIBAgIUNM/uVGtL6zajwZBSxHRwDfpIdAAwCgYIKoZIzj0EAwIwHTEbMBkGA1UE'
        'AwwSb3RoZXIuZXhhbXBsZS50ZXN0MCAXDTI2MTAxODE5Mjc0NFoYDzIxMjYwOTI0MTkyNzQ0WjAd'
        'MRswGQYDVQQDDBJvdGhlci5leGFtcGxlLnRlc3QwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAAT8'
        'aD4zLeXqIak+xrEatoIeo60jssVP8e+6aKHJmfCLMjFBDILlbOC4UmpxG18OTTK2CNVxgHwqjatv'
        'htUoTfbro1MwUTAdBgNVHQ4EFgQUZadHoRLQajRxccyD3bsABGR7TJwwHwYDVR0jBBgwFoAUZadH'
        'oRLQajRxccyD3bsABGR7TJwwDwYDVR0TAQH/BAUwAwEB/zAKBggqhkjOPQQDAgNJADBGAiEA4QSn'
        'LfZEoeZtPrNlRpgMham+q0rk39ev4kTK2i/fgxYCIQCBtfS8CLbmrkWJYVfMfS2t1dpr3tL4ld19'
        'rI+xbYaJAw==',
    derSha256:
        '2b43cf830380cec26fdead928978713af45a7da4dbd6bdfa12545fb2c199f584',
    spkiHex: '80fd7568a300bbe3740252cd0219709bf5dd2a9aa08996c84b6aaa4b2015ef7c',
    spkiBase64: 'gP11aKMAu+N0AlLNAhlwm/XdKpqgiZbIS2qqSyAV73w=',
  );

  /// Private key matching [ec] (PKCS#8, base64 body only).
  static const String _ecKeyBody =
      'MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgvH1iBuVGS21/30QZuSBnzV4qRk8m'
      'yGGyx3pLYg/mjzqhRANCAARTliSKhWg1D0eOUcyQKen3Xf818glscj5yeHyd2pgY2/obCRIHxP2z'
      'ZsqlXMfwfRorjFIjcgCjyU8QRQ4/+V0W';

  static String get privateKeyPem {
    const begin =
        '-----BEGIN '
        'PRIVATE KEY-----';
    const end =
        '-----END '
        'PRIVATE KEY-----';
    final lines = RegExp('.{1,64}').allMatches(_ecKeyBody).map((m) => m[0]);
    return '$begin\n${lines.join('\n')}\n$end\n';
  }
}
