import 'dart:async' as i3;
import 'dart:convert' as i4;
import 'dart:typed_data' as i6;

import 'package:http/http.dart' as i2;
import 'package:mockito/mockito.dart' as i1;
import 'package:mockito/src/dummies.dart' as i5;

class _FakeResponse_0 extends i1.SmartFake implements i2.Response {
  _FakeResponse_0(super.parent, super.parentInvocation);
}

class _FakeStreamedResponse_1 extends i1.SmartFake
    implements i2.StreamedResponse {
  _FakeStreamedResponse_1(super.parent, super.parentInvocation);
}

/// A class which mocks [Client].
///
/// See the documentation for Mockito's code generation for more information.
class MockClient extends i1.Mock implements i2.Client {
  MockClient() {
    i1.throwOnMissingStub(this);
  }

  @override
  i3.Future<i2.Response> head(Uri? url, {Map<String, String>? headers}) =>
      (super.noSuchMethod(
            Invocation.method(#head, [url], {#headers: headers}),
            returnValue: i3.Future<i2.Response>.value(
              _FakeResponse_0(
                this,
                Invocation.method(#head, [url], {#headers: headers}),
              ),
            ),
          )
          as i3.Future<i2.Response>);

  @override
  i3.Future<i2.Response> get(Uri? url, {Map<String, String>? headers}) =>
      (super.noSuchMethod(
            Invocation.method(#get, [url], {#headers: headers}),
            returnValue: i3.Future<i2.Response>.value(
              _FakeResponse_0(
                this,
                Invocation.method(#get, [url], {#headers: headers}),
              ),
            ),
          )
          as i3.Future<i2.Response>);

  @override
  i3.Future<i2.Response> post(
    Uri? url, {
    Map<String, String>? headers,
    Object? body,
    i4.Encoding? encoding,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #post,
              [url],
              {#headers: headers, #body: body, #encoding: encoding},
            ),
            returnValue: i3.Future<i2.Response>.value(
              _FakeResponse_0(
                this,
                Invocation.method(
                  #post,
                  [url],
                  {#headers: headers, #body: body, #encoding: encoding},
                ),
              ),
            ),
          )
          as i3.Future<i2.Response>);

  @override
  i3.Future<i2.Response> put(
    Uri? url, {
    Map<String, String>? headers,
    Object? body,
    i4.Encoding? encoding,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #put,
              [url],
              {#headers: headers, #body: body, #encoding: encoding},
            ),
            returnValue: i3.Future<i2.Response>.value(
              _FakeResponse_0(
                this,
                Invocation.method(
                  #put,
                  [url],
                  {#headers: headers, #body: body, #encoding: encoding},
                ),
              ),
            ),
          )
          as i3.Future<i2.Response>);

  @override
  i3.Future<i2.Response> patch(
    Uri? url, {
    Map<String, String>? headers,
    Object? body,
    i4.Encoding? encoding,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #patch,
              [url],
              {#headers: headers, #body: body, #encoding: encoding},
            ),
            returnValue: i3.Future<i2.Response>.value(
              _FakeResponse_0(
                this,
                Invocation.method(
                  #patch,
                  [url],
                  {#headers: headers, #body: body, #encoding: encoding},
                ),
              ),
            ),
          )
          as i3.Future<i2.Response>);

  @override
  i3.Future<i2.Response> delete(
    Uri? url, {
    Map<String, String>? headers,
    Object? body,
    i4.Encoding? encoding,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #delete,
              [url],
              {#headers: headers, #body: body, #encoding: encoding},
            ),
            returnValue: i3.Future<i2.Response>.value(
              _FakeResponse_0(
                this,
                Invocation.method(
                  #delete,
                  [url],
                  {#headers: headers, #body: body, #encoding: encoding},
                ),
              ),
            ),
          )
          as i3.Future<i2.Response>);

  @override
  i3.Future<String> read(Uri? url, {Map<String, String>? headers}) =>
      (super.noSuchMethod(
            Invocation.method(#read, [url], {#headers: headers}),
            returnValue: i3.Future<String>.value(
              i5.dummyValue<String>(
                this,
                Invocation.method(#read, [url], {#headers: headers}),
              ),
            ),
          )
          as i3.Future<String>);

  @override
  i3.Future<i6.Uint8List> readBytes(
    Uri? url, {
    Map<String, String>? headers,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#readBytes, [url], {#headers: headers}),
            returnValue: i3.Future<i6.Uint8List>.value(i6.Uint8List(0)),
          )
          as i3.Future<i6.Uint8List>);

  @override
  i3.Future<i2.StreamedResponse> send(i2.BaseRequest? request) =>
      (super.noSuchMethod(
            Invocation.method(#send, [request]),
            returnValue: i3.Future<i2.StreamedResponse>.value(
              _FakeStreamedResponse_1(
                this,
                Invocation.method(#send, [request]),
              ),
            ),
          )
          as i3.Future<i2.StreamedResponse>);

  @override
  void close() => super.noSuchMethod(
    Invocation.method(#close, []),
    returnValueForMissingStub: null,
  );
}
