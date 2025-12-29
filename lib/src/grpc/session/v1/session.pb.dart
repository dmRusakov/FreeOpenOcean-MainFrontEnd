// This is a generated file - do not edit.
//
// Generated from session/v1/session.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Make
class MakeRequest extends $pb.GeneratedMessage {
  factory MakeRequest({
    $core.String? username,
    $core.String? password,
  }) {
    final result = create();
    if (username != null) result.username = username;
    if (password != null) result.password = password;
    return result;
  }

  MakeRequest._();

  factory MakeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MakeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MakeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'session.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'username')
    ..aOS(2, _omitFieldNames ? '' : 'password')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MakeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MakeRequest copyWith(void Function(MakeRequest) updates) =>
      super.copyWith((message) => updates(message as MakeRequest))
          as MakeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MakeRequest create() => MakeRequest._();
  @$core.override
  MakeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MakeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MakeRequest>(create);
  static MakeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get password => $_getSZ(1);
  @$pb.TagNumber(2)
  set password($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPassword() => $_has(1);
  @$pb.TagNumber(2)
  void clearPassword() => $_clearField(2);
}

class MakeResponse extends $pb.GeneratedMessage {
  factory MakeResponse({
    $core.bool? success,
    $core.String? token,
    $core.String? userId,
    $core.String? sessionExpired,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (token != null) result.token = token;
    if (userId != null) result.userId = userId;
    if (sessionExpired != null) result.sessionExpired = sessionExpired;
    return result;
  }

  MakeResponse._();

  factory MakeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MakeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MakeResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'session.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOS(3, _omitFieldNames ? '' : 'userId')
    ..aOS(4, _omitFieldNames ? '' : 'sessionExpired')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MakeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MakeResponse copyWith(void Function(MakeResponse) updates) =>
      super.copyWith((message) => updates(message as MakeResponse))
          as MakeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MakeResponse create() => MakeResponse._();
  @$core.override
  MakeResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MakeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MakeResponse>(create);
  static MakeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get token => $_getSZ(1);
  @$pb.TagNumber(2)
  set token($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearToken() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get userId => $_getSZ(2);
  @$pb.TagNumber(3)
  set userId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUserId() => $_has(2);
  @$pb.TagNumber(3)
  void clearUserId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get sessionExpired => $_getSZ(3);
  @$pb.TagNumber(4)
  set sessionExpired($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSessionExpired() => $_has(3);
  @$pb.TagNumber(4)
  void clearSessionExpired() => $_clearField(4);
}

/// Check
class CheckRequest extends $pb.GeneratedMessage {
  factory CheckRequest({
    $core.String? username,
  }) {
    final result = create();
    if (username != null) result.username = username;
    return result;
  }

  CheckRequest._();

  factory CheckRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CheckRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CheckRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'session.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'username')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckRequest copyWith(void Function(CheckRequest) updates) =>
      super.copyWith((message) => updates(message as CheckRequest))
          as CheckRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CheckRequest create() => CheckRequest._();
  @$core.override
  CheckRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CheckRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CheckRequest>(create);
  static CheckRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => $_clearField(1);
}

class CheckResponse extends $pb.GeneratedMessage {
  factory CheckResponse({
    $core.bool? isAuthenticated,
    $core.String? sessionExpired,
    $core.String? newToken,
  }) {
    final result = create();
    if (isAuthenticated != null) result.isAuthenticated = isAuthenticated;
    if (sessionExpired != null) result.sessionExpired = sessionExpired;
    if (newToken != null) result.newToken = newToken;
    return result;
  }

  CheckResponse._();

  factory CheckResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CheckResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CheckResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'session.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'isAuthenticated')
    ..aOS(2, _omitFieldNames ? '' : 'sessionExpired')
    ..aOS(3, _omitFieldNames ? '' : 'newToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckResponse copyWith(void Function(CheckResponse) updates) =>
      super.copyWith((message) => updates(message as CheckResponse))
          as CheckResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CheckResponse create() => CheckResponse._();
  @$core.override
  CheckResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CheckResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CheckResponse>(create);
  static CheckResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get isAuthenticated => $_getBF(0);
  @$pb.TagNumber(1)
  set isAuthenticated($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIsAuthenticated() => $_has(0);
  @$pb.TagNumber(1)
  void clearIsAuthenticated() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sessionExpired => $_getSZ(1);
  @$pb.TagNumber(2)
  set sessionExpired($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionExpired() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionExpired() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get newToken => $_getSZ(2);
  @$pb.TagNumber(3)
  set newToken($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNewToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearNewToken() => $_clearField(3);
}

/// Drop
class DropRequest extends $pb.GeneratedMessage {
  factory DropRequest({
    $core.String? username,
  }) {
    final result = create();
    if (username != null) result.username = username;
    return result;
  }

  DropRequest._();

  factory DropRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DropRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DropRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'session.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'username')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DropRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DropRequest copyWith(void Function(DropRequest) updates) =>
      super.copyWith((message) => updates(message as DropRequest))
          as DropRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DropRequest create() => DropRequest._();
  @$core.override
  DropRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DropRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DropRequest>(create);
  static DropRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => $_clearField(1);
}

class DropResponse extends $pb.GeneratedMessage {
  factory DropResponse({
    $core.bool? success,
  }) {
    final result = create();
    if (success != null) result.success = success;
    return result;
  }

  DropResponse._();

  factory DropResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DropResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DropResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'session.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DropResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DropResponse copyWith(void Function(DropResponse) updates) =>
      super.copyWith((message) => updates(message as DropResponse))
          as DropResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DropResponse create() => DropResponse._();
  @$core.override
  DropResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DropResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DropResponse>(create);
  static DropResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);
}

/// Info
class InfoRequest extends $pb.GeneratedMessage {
  factory InfoRequest({
    $core.String? username,
  }) {
    final result = create();
    if (username != null) result.username = username;
    return result;
  }

  InfoRequest._();

  factory InfoRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InfoRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InfoRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'session.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'username')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InfoRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InfoRequest copyWith(void Function(InfoRequest) updates) =>
      super.copyWith((message) => updates(message as InfoRequest))
          as InfoRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InfoRequest create() => InfoRequest._();
  @$core.override
  InfoRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InfoRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InfoRequest>(create);
  static InfoRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => $_clearField(1);
}

class InfoResponse extends $pb.GeneratedMessage {
  factory InfoResponse({
    $core.String? userId,
    $core.String? username,
    $core.String? firstName,
    $core.String? middleName,
    $core.String? lastName,
    $core.String? email,
    $core.Iterable<$core.String>? roles,
    $core.String? language,
    $core.String? timezone,
    $core.String? theme,
    $core.bool? notifications,
    $core.String? sessionExpired,
    $core.String? profilePicture,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (username != null) result.username = username;
    if (firstName != null) result.firstName = firstName;
    if (middleName != null) result.middleName = middleName;
    if (lastName != null) result.lastName = lastName;
    if (email != null) result.email = email;
    if (roles != null) result.roles.addAll(roles);
    if (language != null) result.language = language;
    if (timezone != null) result.timezone = timezone;
    if (theme != null) result.theme = theme;
    if (notifications != null) result.notifications = notifications;
    if (sessionExpired != null) result.sessionExpired = sessionExpired;
    if (profilePicture != null) result.profilePicture = profilePicture;
    return result;
  }

  InfoResponse._();

  factory InfoResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InfoResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InfoResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'session.v1'),
      createEmptyInstance: create)
    ..aOS(10, _omitFieldNames ? '' : 'userId')
    ..aOS(11, _omitFieldNames ? '' : 'username')
    ..aOS(12, _omitFieldNames ? '' : 'firstName')
    ..aOS(13, _omitFieldNames ? '' : 'middleName')
    ..aOS(14, _omitFieldNames ? '' : 'lastName')
    ..aOS(20, _omitFieldNames ? '' : 'email')
    ..pPS(30, _omitFieldNames ? '' : 'roles')
    ..aOS(40, _omitFieldNames ? '' : 'language')
    ..aOS(41, _omitFieldNames ? '' : 'timezone')
    ..aOS(42, _omitFieldNames ? '' : 'theme')
    ..aOB(43, _omitFieldNames ? '' : 'notifications')
    ..aOS(50, _omitFieldNames ? '' : 'sessionExpired')
    ..aOS(60, _omitFieldNames ? '' : 'profilePicture')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InfoResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InfoResponse copyWith(void Function(InfoResponse) updates) =>
      super.copyWith((message) => updates(message as InfoResponse))
          as InfoResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InfoResponse create() => InfoResponse._();
  @$core.override
  InfoResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InfoResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InfoResponse>(create);
  static InfoResponse? _defaultInstance;

  @$pb.TagNumber(10)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(10)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(10)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(10)
  void clearUserId() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(11)
  set username($core.String value) => $_setString(1, value);
  @$pb.TagNumber(11)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(11)
  void clearUsername() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get firstName => $_getSZ(2);
  @$pb.TagNumber(12)
  set firstName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(12)
  $core.bool hasFirstName() => $_has(2);
  @$pb.TagNumber(12)
  void clearFirstName() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get middleName => $_getSZ(3);
  @$pb.TagNumber(13)
  set middleName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(13)
  $core.bool hasMiddleName() => $_has(3);
  @$pb.TagNumber(13)
  void clearMiddleName() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get lastName => $_getSZ(4);
  @$pb.TagNumber(14)
  set lastName($core.String value) => $_setString(4, value);
  @$pb.TagNumber(14)
  $core.bool hasLastName() => $_has(4);
  @$pb.TagNumber(14)
  void clearLastName() => $_clearField(14);

  @$pb.TagNumber(20)
  $core.String get email => $_getSZ(5);
  @$pb.TagNumber(20)
  set email($core.String value) => $_setString(5, value);
  @$pb.TagNumber(20)
  $core.bool hasEmail() => $_has(5);
  @$pb.TagNumber(20)
  void clearEmail() => $_clearField(20);

  @$pb.TagNumber(30)
  $pb.PbList<$core.String> get roles => $_getList(6);

  @$pb.TagNumber(40)
  $core.String get language => $_getSZ(7);
  @$pb.TagNumber(40)
  set language($core.String value) => $_setString(7, value);
  @$pb.TagNumber(40)
  $core.bool hasLanguage() => $_has(7);
  @$pb.TagNumber(40)
  void clearLanguage() => $_clearField(40);

  @$pb.TagNumber(41)
  $core.String get timezone => $_getSZ(8);
  @$pb.TagNumber(41)
  set timezone($core.String value) => $_setString(8, value);
  @$pb.TagNumber(41)
  $core.bool hasTimezone() => $_has(8);
  @$pb.TagNumber(41)
  void clearTimezone() => $_clearField(41);

  @$pb.TagNumber(42)
  $core.String get theme => $_getSZ(9);
  @$pb.TagNumber(42)
  set theme($core.String value) => $_setString(9, value);
  @$pb.TagNumber(42)
  $core.bool hasTheme() => $_has(9);
  @$pb.TagNumber(42)
  void clearTheme() => $_clearField(42);

  @$pb.TagNumber(43)
  $core.bool get notifications => $_getBF(10);
  @$pb.TagNumber(43)
  set notifications($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(43)
  $core.bool hasNotifications() => $_has(10);
  @$pb.TagNumber(43)
  void clearNotifications() => $_clearField(43);

  @$pb.TagNumber(50)
  $core.String get sessionExpired => $_getSZ(11);
  @$pb.TagNumber(50)
  set sessionExpired($core.String value) => $_setString(11, value);
  @$pb.TagNumber(50)
  $core.bool hasSessionExpired() => $_has(11);
  @$pb.TagNumber(50)
  void clearSessionExpired() => $_clearField(50);

  @$pb.TagNumber(60)
  $core.String get profilePicture => $_getSZ(12);
  @$pb.TagNumber(60)
  set profilePicture($core.String value) => $_setString(12, value);
  @$pb.TagNumber(60)
  $core.bool hasProfilePicture() => $_has(12);
  @$pb.TagNumber(60)
  void clearProfilePicture() => $_clearField(60);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
