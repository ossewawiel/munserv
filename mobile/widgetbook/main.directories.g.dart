// dart format width=80
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:widgetbook/widgetbook.dart' as _widgetbook;

import 'use_cases/app_logo.dart'
    as _asset_munserv_mobile_widgetbook_use_cases_app_logo;
import 'use_cases/branded_scaffold.dart'
    as _asset_munserv_mobile_widgetbook_use_cases_branded_scaffold;
import 'use_cases/branding_header.dart'
    as _asset_munserv_mobile_widgetbook_use_cases_branding_header;
import 'use_cases/design_tokens.dart'
    as _asset_munserv_mobile_widgetbook_use_cases_design_tokens;
import 'use_cases/empty_state.dart'
    as _asset_munserv_mobile_widgetbook_use_cases_empty_state;
import 'use_cases/error_display.dart'
    as _asset_munserv_mobile_widgetbook_use_cases_error_display;
import 'use_cases/form_error_banner.dart'
    as _asset_munserv_mobile_widgetbook_use_cases_form_error_banner;
import 'use_cases/heat_indicator.dart'
    as _asset_munserv_mobile_widgetbook_use_cases_heat_indicator;
import 'use_cases/issue_card.dart'
    as _asset_munserv_mobile_widgetbook_use_cases_issue_card;
import 'use_cases/issue_location_map.dart'
    as _asset_munserv_mobile_widgetbook_use_cases_issue_location_map;
import 'use_cases/issue_type_icon.dart'
    as _asset_munserv_mobile_widgetbook_use_cases_issue_type_icon;
import 'use_cases/loading_spinner.dart'
    as _asset_munserv_mobile_widgetbook_use_cases_loading_spinner;
import 'use_cases/map_background.dart'
    as _asset_munserv_mobile_widgetbook_use_cases_map_background;
import 'use_cases/munserv_app_bar.dart'
    as _asset_munserv_mobile_widgetbook_use_cases_munserv_app_bar;
import 'use_cases/photo_thumbnail_carousel.dart'
    as _asset_munserv_mobile_widgetbook_use_cases_photo_thumbnail_carousel;
import 'use_cases/quick_action_card.dart'
    as _asset_munserv_mobile_widgetbook_use_cases_quick_action_card;
import 'use_cases/step_indicator.dart'
    as _asset_munserv_mobile_widgetbook_use_cases_step_indicator;

final directories = <_widgetbook.WidgetbookNode>[
  _widgetbook.WidgetbookFolder(
    name: 'features',
    children: [
      _widgetbook.WidgetbookFolder(
        name: 'issues',
        children: [
          _widgetbook.WidgetbookFolder(
            name: 'presentation',
            children: [
              _widgetbook.WidgetbookFolder(
                name: 'widgets',
                children: [
                  _widgetbook.WidgetbookComponent(
                    name: 'HeatIndicator',
                    useCases: [
                      _widgetbook.WidgetbookUseCase(
                        name: 'Heat 0',
                        builder:
                            _asset_munserv_mobile_widgetbook_use_cases_heat_indicator
                                .heatIndicator0,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Heat 100',
                        builder:
                            _asset_munserv_mobile_widgetbook_use_cases_heat_indicator
                                .heatIndicator100,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Heat 25',
                        builder:
                            _asset_munserv_mobile_widgetbook_use_cases_heat_indicator
                                .heatIndicator25,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Heat 50',
                        builder:
                            _asset_munserv_mobile_widgetbook_use_cases_heat_indicator
                                .heatIndicator50,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Heat 75',
                        builder:
                            _asset_munserv_mobile_widgetbook_use_cases_heat_indicator
                                .heatIndicator75,
                      ),
                    ],
                  ),
                  _widgetbook.WidgetbookComponent(
                    name: 'IssueCard',
                    useCases: [
                      _widgetbook.WidgetbookUseCase(
                        name: 'Compact',
                        builder:
                            _asset_munserv_mobile_widgetbook_use_cases_issue_card
                                .issueCardCompact,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'List',
                        builder:
                            _asset_munserv_mobile_widgetbook_use_cases_issue_card
                                .issueCardList,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Map preview',
                        builder:
                            _asset_munserv_mobile_widgetbook_use_cases_issue_card
                                .issueCardMapPreview,
                      ),
                    ],
                  ),
                  _widgetbook.WidgetbookComponent(
                    name: 'IssueTypeIcon',
                    useCases: [
                      _widgetbook.WidgetbookUseCase(
                        name: 'Illegal dumping',
                        builder:
                            _asset_munserv_mobile_widgetbook_use_cases_issue_type_icon
                                .issueTypeIconIllegalDumping,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Other',
                        builder:
                            _asset_munserv_mobile_widgetbook_use_cases_issue_type_icon
                                .issueTypeIconOther,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Pothole',
                        builder:
                            _asset_munserv_mobile_widgetbook_use_cases_issue_type_icon
                                .issueTypeIconPothole,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Road damage',
                        builder:
                            _asset_munserv_mobile_widgetbook_use_cases_issue_type_icon
                                .issueTypeIconRoadDamage,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Sewage leak',
                        builder:
                            _asset_munserv_mobile_widgetbook_use_cases_issue_type_icon
                                .issueTypeIconSewageLeak,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Street light',
                        builder:
                            _asset_munserv_mobile_widgetbook_use_cases_issue_type_icon
                                .issueTypeIconStreetLight,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Traffic light',
                        builder:
                            _asset_munserv_mobile_widgetbook_use_cases_issue_type_icon
                                .issueTypeIconTrafficLight,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Water leak',
                        builder:
                            _asset_munserv_mobile_widgetbook_use_cases_issue_type_icon
                                .issueTypeIconWaterLeak,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  ),
  _widgetbook.WidgetbookFolder(
    name: 'shared',
    children: [
      _widgetbook.WidgetbookFolder(
        name: 'widgets',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'AppLogo',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Sizes',
                builder:
                    _asset_munserv_mobile_widgetbook_use_cases_app_logo.appLogo,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'BrandedScaffold',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _asset_munserv_mobile_widgetbook_use_cases_branded_scaffold
                        .brandedScaffold,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'BrandingHeader',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _asset_munserv_mobile_widgetbook_use_cases_branding_header
                        .brandingHeader,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'EmptyState',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Location error',
                builder: _asset_munserv_mobile_widgetbook_use_cases_empty_state
                    .emptyStateLocationError,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Network error',
                builder: _asset_munserv_mobile_widgetbook_use_cases_empty_state
                    .emptyStateNetworkError,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'No issues',
                builder: _asset_munserv_mobile_widgetbook_use_cases_empty_state
                    .emptyStateNoIssues,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'No reports',
                builder: _asset_munserv_mobile_widgetbook_use_cases_empty_state
                    .emptyStateNoReports,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'No results',
                builder: _asset_munserv_mobile_widgetbook_use_cases_empty_state
                    .emptyStateNoResults,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'ErrorDisplay',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _asset_munserv_mobile_widgetbook_use_cases_error_display
                        .errorDisplay,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'FormErrorBanner',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _asset_munserv_mobile_widgetbook_use_cases_form_error_banner
                        .formErrorBanner,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'IssueLocationMap',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _asset_munserv_mobile_widgetbook_use_cases_issue_location_map
                        .issueLocationMap,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'LoadingSpinner',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _asset_munserv_mobile_widgetbook_use_cases_loading_spinner
                        .loadingSpinner,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'MapBackground',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _asset_munserv_mobile_widgetbook_use_cases_map_background
                        .mapBackground,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'MunServAppBar',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _asset_munserv_mobile_widgetbook_use_cases_munserv_app_bar
                        .munservAppBar,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'PhotoThumbnailCarousel',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _asset_munserv_mobile_widgetbook_use_cases_photo_thumbnail_carousel
                        .photoThumbnailCarousel,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'QuickActionCard',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _asset_munserv_mobile_widgetbook_use_cases_quick_action_card
                        .quickActionCard,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'StepIndicator',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _asset_munserv_mobile_widgetbook_use_cases_step_indicator
                        .stepIndicator,
              ),
            ],
          ),
        ],
      ),
    ],
  ),
  _widgetbook.WidgetbookFolder(
    name: 'widgetbook',
    children: [
      _widgetbook.WidgetbookFolder(
        name: 'use_cases',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'DesignTokensShowcase',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Design/Tokens',
                builder:
                    _asset_munserv_mobile_widgetbook_use_cases_design_tokens
                        .designTokens,
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];
