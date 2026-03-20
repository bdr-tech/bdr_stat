import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// 충돌 해결 전략
enum ConflictResolutionStrategy {
  keepLocal,     // 로컬 데이터 유지
  keepServer,    // 서버 데이터 유지
  merge,         // 병합 (최신 값 선택)
  manual,        // 수동 선택
}

/// 충돌 데이터 차이점
class ConflictDifference {
  final String field;
  final String fieldLabel;
  final dynamic localValue;
  final dynamic serverValue;
  final DateTime? localUpdatedAt;
  final DateTime? serverUpdatedAt;
  final String? localDeviceName;
  final String? serverDeviceName;

  const ConflictDifference({
    required this.field,
    required this.fieldLabel,
    required this.localValue,
    required this.serverValue,
    this.localUpdatedAt,
    this.serverUpdatedAt,
    this.localDeviceName,
    this.serverDeviceName,
  });

  bool get hasDifference => localValue != serverValue;

  /// 가장 최근 값 반환
  dynamic get newerValue {
    if (localUpdatedAt == null && serverUpdatedAt == null) {
      return serverValue; // 기본적으로 서버 우선
    }
    if (localUpdatedAt == null) return serverValue;
    if (serverUpdatedAt == null) return localValue;
    return localUpdatedAt!.isAfter(serverUpdatedAt!) ? localValue : serverValue;
  }
}

/// 충돌 정보
class ConflictInfo {
  final String matchLocalUuid;
  final String conflictType;
  final List<ConflictDifference> differences;
  final DateTime localUpdatedAt;
  final DateTime serverUpdatedAt;
  final String? localDeviceName;
  final String? serverDeviceName;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;

  const ConflictInfo({
    required this.matchLocalUuid,
    required this.conflictType,
    required this.differences,
    required this.localUpdatedAt,
    required this.serverUpdatedAt,
    this.localDeviceName,
    this.serverDeviceName,
    required this.localData,
    required this.serverData,
  });

  /// 주요 차이점만 필터링
  List<ConflictDifference> get significantDifferences =>
      differences.where((d) => d.hasDifference).toList();
}

/// 충돌 해결 결과
class ConflictResolutionResult {
  final ConflictResolutionStrategy strategy;
  final Map<String, dynamic>? mergedData;
  final Map<String, dynamic>? selectedValues;

  const ConflictResolutionResult({
    required this.strategy,
    this.mergedData,
    this.selectedValues,
  });
}

/// 충돌 해결 다이얼로그 표시
Future<ConflictResolutionResult?> showConflictResolutionDialog({
  required BuildContext context,
  required ConflictInfo conflict,
  bool allowMerge = true,
}) async {
  return showDialog<ConflictResolutionResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ConflictResolutionDialog(
      conflict: conflict,
      allowMerge: allowMerge,
    ),
  );
}

/// 충돌 해결 다이얼로그
class ConflictResolutionDialog extends StatefulWidget {
  const ConflictResolutionDialog({
    super.key,
    required this.conflict,
    this.allowMerge = true,
  });

  final ConflictInfo conflict;
  final bool allowMerge;

  @override
  State<ConflictResolutionDialog> createState() => _ConflictResolutionDialogState();
}

class _ConflictResolutionDialogState extends State<ConflictResolutionDialog> {
  ConflictResolutionStrategy? _selectedStrategy;
  final Map<String, dynamic> _selectedValues = {};
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    // 기본 선택값 초기화 (최신 값으로)
    for (final diff in widget.conflict.differences) {
      _selectedValues[diff.field] = diff.newerValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            _buildHeader(),

            // 내용
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 충돌 요약
                    _buildConflictSummary(),
                    const SizedBox(height: 20),

                    // 해결 전략 선택
                    _buildStrategySelection(),
                    const SizedBox(height: 20),

                    // 상세 차이점 (수동 선택 시)
                    if (_selectedStrategy == ConflictResolutionStrategy.manual)
                      _buildManualSelection(),

                    // 상세보기 토글
                    if (_selectedStrategy != ConflictResolutionStrategy.manual) ...[
                      _buildDetailsToggle(),
                      if (_showDetails) _buildDifferencesList(),
                    ],
                  ],
                ),
              ),
            ),

            // 하단 버튼
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.warningColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '데이터 충돌 감지',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.conflict.conflictType == 'server_newer'
                      ? '서버에 더 최신 데이터가 있습니다'
                      : '다른 기기에서 수정된 데이터가 있습니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 로컬 정보
              Expanded(
                child: _buildDeviceInfo(
                  icon: Icons.phone_android,
                  label: '이 기기',
                  deviceName: widget.conflict.localDeviceName ?? '로컬',
                  updatedAt: widget.conflict.localUpdatedAt,
                  isLocal: true,
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Icon(Icons.sync_problem, color: AppTheme.warningColor),
              ),

              // 서버 정보
              Expanded(
                child: _buildDeviceInfo(
                  icon: Icons.cloud,
                  label: '서버',
                  deviceName: widget.conflict.serverDeviceName ?? '다른 기기',
                  updatedAt: widget.conflict.serverUpdatedAt,
                  isLocal: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.conflict.significantDifferences.length}개의 차이점이 발견되었습니다',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfo({
    required IconData icon,
    required String label,
    required String deviceName,
    required DateTime updatedAt,
    required bool isLocal,
  }) {
    final isNewer = isLocal
        ? widget.conflict.localUpdatedAt.isAfter(widget.conflict.serverUpdatedAt)
        : widget.conflict.serverUpdatedAt.isAfter(widget.conflict.localUpdatedAt);

    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isNewer
                ? AppTheme.successColor.withValues(alpha: 0.2)
                : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isNewer ? AppTheme.successColor : AppTheme.dividerColor,
              width: isNewer ? 2 : 1,
            ),
          ),
          child: Icon(
            icon,
            color: isNewer ? AppTheme.successColor : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          deviceName,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        if (isNewer)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.successColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '최신',
              style: TextStyle(fontSize: 9, color: Colors.white),
            ),
          ),
        Text(
          _formatDateTime(updatedAt),
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textHint,
          ),
        ),
      ],
    );
  }

  Widget _buildStrategySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '해결 방법 선택',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        _buildStrategyOption(
          strategy: ConflictResolutionStrategy.keepLocal,
          icon: Icons.phone_android,
          title: '이 기기 데이터 유지',
          description: '현재 기기에서 기록한 데이터를 사용합니다',
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 8),

        _buildStrategyOption(
          strategy: ConflictResolutionStrategy.keepServer,
          icon: Icons.cloud,
          title: '서버 데이터 사용',
          description: '서버에 저장된 데이터로 대체합니다',
          color: AppTheme.secondaryColor,
        ),

        if (widget.allowMerge) ...[
          const SizedBox(height: 8),
          _buildStrategyOption(
            strategy: ConflictResolutionStrategy.merge,
            icon: Icons.merge_type,
            title: '자동 병합 (최신 값 선택)',
            description: '각 항목별로 더 최근에 수정된 값을 선택합니다',
            color: AppTheme.successColor,
          ),
          const SizedBox(height: 8),
          _buildStrategyOption(
            strategy: ConflictResolutionStrategy.manual,
            icon: Icons.tune,
            title: '수동 선택',
            description: '각 항목을 직접 선택합니다',
            color: AppTheme.primaryColor,
          ),
        ],
      ],
    );
  }

  Widget _buildStrategyOption({
    required ConflictResolutionStrategy strategy,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final isSelected = _selectedStrategy == strategy;

    return InkWell(
      onTap: () => setState(() => _selectedStrategy = strategy),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? color : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Radio<ConflictResolutionStrategy>(
              value: strategy,
              groupValue: _selectedStrategy,
              onChanged: (value) => setState(() => _selectedStrategy = value),
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '각 항목 선택',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.conflict.significantDifferences.map((diff) => _buildFieldSelector(diff)),
      ],
    );
  }

  Widget _buildFieldSelector(ConflictDifference diff) {
    final selectedValue = _selectedValues[diff.field];
    final isLocalSelected = selectedValue == diff.localValue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            diff.fieldLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildValueOption(
                  label: '이 기기',
                  value: diff.localValue,
                  isSelected: isLocalSelected,
                  onTap: () => setState(() => _selectedValues[diff.field] = diff.localValue),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildValueOption(
                  label: '서버',
                  value: diff.serverValue,
                  isSelected: !isLocalSelected,
                  onTap: () => setState(() => _selectedValues[diff.field] = diff.serverValue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueOption({
    required String label,
    required dynamic value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatValue(value),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsToggle() {
    return InkWell(
      onTap: () => setState(() => _showDetails = !_showDetails),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              _showDetails ? Icons.expand_less : Icons.expand_more,
              size: 20,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              _showDetails ? '차이점 숨기기' : '차이점 보기',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifferencesList() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: widget.conflict.significantDifferences.map((diff) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    diff.fieldLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatValue(diff.localValue),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward, size: 12, color: AppTheme.textHint),
                      ),
                      Text(
                        _formatValue(diff.serverValue),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('나중에'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _selectedStrategy == null
                ? null
                : () {
                    final result = ConflictResolutionResult(
                      strategy: _selectedStrategy!,
                      mergedData: _selectedStrategy == ConflictResolutionStrategy.merge
                          ? _buildMergedData()
                          : null,
                      selectedValues: _selectedStrategy == ConflictResolutionStrategy.manual
                          ? Map.from(_selectedValues)
                          : null,
                    );
                    Navigator.pop(context, result);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              disabledBackgroundColor: AppTheme.dividerColor,
            ),
            child: Text(_selectedStrategy == null ? '선택하세요' : '적용'),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _buildMergedData() {
    final merged = <String, dynamic>{};
    for (final diff in widget.conflict.differences) {
      merged[diff.field] = diff.newerValue;
    }
    return merged;
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatValue(dynamic value) {
    if (value == null) return '-';
    if (value is int || value is double) return value.toString();
    if (value is bool) return value ? '예' : '아니오';
    if (value is DateTime) return _formatDateTime(value);
    return value.toString();
  }
}
