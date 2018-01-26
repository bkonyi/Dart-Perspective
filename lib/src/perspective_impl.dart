// Copyright (c) 2018, the Dart-Perspective API project authors.
// Please see the AUTHORS file for details. All rights reserved.
// Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';

/// A filter class used to filter [PerspectiveResponse]s.
///
/// Used to determine whether or not a comment associated with a
/// [PerspectiveResponse] should be filtered based on provided thresholds.
class PerspectiveFilter {
  final Map<PerspectiveModel, double> _thresholds = new Map();

  /// Returns the [PerspectiveModel] associated with the most recently filtered
  /// [PerspectiveResponse].
  ///
  /// This field is determined by the largest score that exceeds a provided
  /// threshold.
  PerspectiveModel get lastFilterReason => _lastFilterReason;
  PerspectiveModel _lastFilterReason;

  PerspectiveFilter([Map<PerspectiveModel, double> thresholds]) {
    if (thresholds != null) _thresholds.addAll(thresholds);
  }

  /// Adds a threshold value for a particular [PerspectiveModel].
  ///
  /// Multiple calls with the same model will overwrite prior threshold values.
  void add(PerspectiveModel model, double threshold) =>
      _thresholds[model] = threshold;

  /// Removes set thresholds associated with a given [PerspectiveModel].
  void remove(PerspectiveModel model) => _thresholds.remove(model);

  /// Clears all threshold values for this filter.
  void clear() => _thresholds.clear();

  /// Returns the threshold value associated with a [PerspectiveModel].
  ///
  /// If [model] does not have a threshold associated with it, a default value of
  /// `1.0` is returned.
  double modelThreshold(PerspectiveModel model) =>
      _thresholds.containsKey(model) ? _thresholds[model] : 1.0;

  /// Determines whether or not a [PerspectiveResponse] should be filtered based
  /// on the previously set threshold values.
  ///
  /// Returns `true` if a model score in [response] exceeds its threshold value.
  bool shouldFilter(PerspectiveResponse response) {
    bool filter = false;
    double maxResult = 0.0;

    Function filterHelper = (a, t, v) {
      if (v >= t && v >= maxResult) {
        filter = true;
        maxResult = v;
        _lastFilterReason = a;
      }
    };

    _thresholds.forEach((a, t) {
      switch (a) {
        case PerspectiveModel.Toxicity:
          filterHelper(a, t, response.toxicity);
          break;
        case PerspectiveModel.SevereToxicity:
          filterHelper(a, t, response.severeToxicity);
          break;
        case PerspectiveModel.ToxicityFast:
          filterHelper(a, t, response.toxicityFast);
          break;
        case PerspectiveModel.AttackOnAuthor:
          filterHelper(a, t, response.attackOnAuthor);
          break;
        case PerspectiveModel.AttackOnCommenter:
          filterHelper(a, t, response.attackOnCommenter);
          break;
        case PerspectiveModel.Incoherent:
          filterHelper(a, t, response.incoherent);
          break;
        case PerspectiveModel.Inflammatory:
          filterHelper(a, t, response.inflammatory);
          break;
        case PerspectiveModel.LikelyToReject:
          filterHelper(a, t, response.likelyToReject);
          break;
        case PerspectiveModel.Obscene:
          filterHelper(a, t, response.obscene);
          break;
        case PerspectiveModel.Spam:
          filterHelper(a, t, response.spam);
          break;
        case PerspectiveModel.Unsubstantial:
          filterHelper(a, t, response.unsubstantial);
          break;
        default:
          throw new UnimplementedError('$a is not a valid Perspective type.');
      }
    });
    return filter;
  }
}

class PerspectiveResponse {
  /// The string analyzed by the Perspective API.
  final String body;

  /// The list of models used to analyze [body].
  final List<PerspectiveModel> models;

  final Map _results;

  double get toxicity => summaryScore(PerspectiveModel.Toxicity);

  double get severeToxicity =>
      summaryScore(PerspectiveModel.SevereToxicity);

  double get toxicityFast => summaryScore(PerspectiveModel.ToxicityFast);

  double get attackOnAuthor =>
      summaryScore(PerspectiveModel.AttackOnAuthor);

  double get attackOnCommenter =>
      summaryScore(PerspectiveModel.AttackOnCommenter);

  double get incoherent => summaryScore(PerspectiveModel.Incoherent);

  double get inflammatory => summaryScore(PerspectiveModel.Inflammatory);

  double get likelyToReject =>
      summaryScore(PerspectiveModel.LikelyToReject);

  double get obscene => summaryScore(PerspectiveModel.Obscene);

  double get spam => summaryScore(PerspectiveModel.Spam);

  double get unsubstantial => summaryScore(PerspectiveModel.Unsubstantial);

  PerspectiveResponse(
      String this.body, List<PerspectiveModel> this.models, Map results)
      : _results = results;

  /// Returns the summary score for a given model.
  ///
  /// If the provided [PerspectiveModel] was not used in the analyze request, a
  /// default value of `0.0` is returned.
  double summaryScore(
          PerspectiveModel model) =>
      _results['attributeScores']
              .containsKey(perspectiveModelToString(model))
          ? _results['attributeScores'][perspectiveModelToString(model)]
              ['summaryScore']['value']
          : 0.0;

  void _toStringHelper(StringBuffer s, a, v) =>
      s.writeln('${perspectiveModelToString(a)}: $v');

  String _toString(String b) {
    StringBuffer s = new StringBuffer();
    s.writeln('Body: $b');
    if (models.contains(PerspectiveModel.Toxicity))
      _toStringHelper(s, PerspectiveModel.Toxicity, toxicity);
    if (models.contains(PerspectiveModel.SevereToxicity))
      _toStringHelper(s, PerspectiveModel.SevereToxicity, severeToxicity);
    if (models.contains(PerspectiveModel.ToxicityFast))
      _toStringHelper(s, PerspectiveModel.ToxicityFast, toxicityFast);
    if (models.contains(PerspectiveModel.AttackOnAuthor))
      _toStringHelper(s, PerspectiveModel.AttackOnAuthor, attackOnAuthor);
    if (models.contains(PerspectiveModel.AttackOnCommenter))
      _toStringHelper(
          s, PerspectiveModel.AttackOnCommenter, attackOnCommenter);
    if (models.contains(PerspectiveModel.Incoherent))
      _toStringHelper(s, PerspectiveModel.Incoherent, incoherent);
    if (models.contains(PerspectiveModel.Inflammatory))
      _toStringHelper(s, PerspectiveModel.Inflammatory, inflammatory);
    if (models.contains(PerspectiveModel.LikelyToReject))
      _toStringHelper(s, PerspectiveModel.LikelyToReject, likelyToReject);
    if (models.contains(PerspectiveModel.Obscene))
      _toStringHelper(s, PerspectiveModel.Obscene, obscene);
    if (models.contains(PerspectiveModel.Spam))
      _toStringHelper(s, PerspectiveModel.Spam, spam);
    if (models.contains(PerspectiveModel.Unsubstantial))
      _toStringHelper(s, PerspectiveModel.Unsubstantial, unsubstantial);
    return s.toString();
  }

  String toSFWString() =>
      _toString('REDACTED');

  String toString() => _toString(body);
}

/// The available models provided by the Perspective API.
///
/// See the [Perspective API documentation](https://github.com/conversationai/perspectiveapi/blob/master/api_reference.md)
/// for detailed descriptions of each model.
enum PerspectiveModel {
  Toxicity,
  SevereToxicity,
  ToxicityFast,
  AttackOnAuthor,
  AttackOnCommenter,
  Incoherent,
  Inflammatory,
  LikelyToReject,
  Obscene,
  Spam,
  Unsubstantial,
}

/// A utility method to convert a [PerspectiveModel] to its corresponding API string.
String perspectiveModelToString(PerspectiveModel a) {
  switch (a) {
    case PerspectiveModel.Toxicity:
      return "TOXICITY";
    case PerspectiveModel.SevereToxicity:
      return "SEVERE_TOXICITY";
    case PerspectiveModel.ToxicityFast:
      return "TOXICITY_FAST";
    case PerspectiveModel.AttackOnAuthor:
      return "ATTACK_ON_AUTHOR";
    case PerspectiveModel.AttackOnCommenter:
      return "ATTACK_ON_COMMENTER";
    case PerspectiveModel.Incoherent:
      return "INCOHERENT";
    case PerspectiveModel.Inflammatory:
      return "INFLAMMATORY";
    case PerspectiveModel.LikelyToReject:
      return "LIKELY_TO_REJECT";
    case PerspectiveModel.Obscene:
      return "OBSCENE";
    case PerspectiveModel.Spam:
      return "SPAM";
    case PerspectiveModel.Unsubstantial:
      return "UNSUBSTANTIAL";
    default:
      throw new ArgumentError('Invalid PerspectiveAttribute: $a');
  }
}

/// Makes requests to the Perspective API.
///
/// [PerspectiveRequester] is used to keep track of metadata used in Perspective
/// API requests. In particular, the [PerspectiveModel]s provided by the constructor
/// or the [addModel] method are remembered, as well as the API key.
///
/// Note: [setApiKey] must be called with a valid API key before [analyze] is called.
class PerspectiveRequester {
  static String _API_KEY;
  static const String _API_ENDPOINT =
      "https://commentanalyzer.googleapis.com/v1alpha1/comments:analyze?key=";

  final List<PerspectiveModel> _models = <PerspectiveModel>[];

  /// Sets the Perspective API key for this program instance.
  ///
  /// Must be called with a valid key before [analyze] can be called.
  static void setApiKey(String key) => _API_KEY = key;

  /// Add a [PerspectiveModel] to be queried when [analyze] is called.
  void addModel(PerspectiveModel attribute) =>
      _models.add(attribute);

  /// Clears all [PerspectiveModel]s associated with this instance of [PerspectiveRequester].
  void clearModels() => _models.clear();

  /// Default constructor for [PerspectiveRequester].
  ///
  /// [attributes] is an optional [List<PerspectiveModel>] which contains the models
  /// to be used by the Perspective API for comment analysis.
  PerspectiveRequester([List<PerspectiveModel> attributes]) {
    _models.addAll(attributes);
  }

  /// Request analysis of a comment using the models declared in the constructor
  /// or [addModel].
  ///
  /// Returns a [Future<PerspectiveResponse>], where [PerspectiveResponse] contains
  /// the scores provided by the requested models.
  Future<PerspectiveResponse> analyze(String body) async {
    final request = {
      "comment": {"text": body},
      "languages": ["en"],
    };

    Map requestModels = {};
    _models.forEach((attribute) {
      requestModels[perspectiveModelToString(attribute)] = {};
    });
    request["requestedAttributes"] = requestModels;

    final response =
        await post(_API_ENDPOINT + _API_KEY, body: JSON.encode(request));
    final results = JSON.decode(response.body);
    return new PerspectiveResponse(body, _models, results);
  }
}
