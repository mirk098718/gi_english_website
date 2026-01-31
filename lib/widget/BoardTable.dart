import 'package:flutter/material.dart';
import 'package:gi_english_website/util/Palette.dart';

class BoardTable extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final List<String> headers;
  final Function(Map<String, dynamic>) onItemTap;
  final String emptyMessage;
  final bool isAdmin;
  final Function(Map<String, dynamic>)? onEditTap;
  final Function(Map<String, dynamic>)? onDeleteTap;

  const BoardTable({
    Key? key,
    required this.items,
    required this.headers,
    required this.onItemTap,
    this.emptyMessage = "등록된 게시글이 없습니다.",
    this.isAdmin = false,
    this.onEditTap,
    this.onDeleteTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(width: 1, color: Palette.black),
        ),
        child: Column(
          children: [
            _buildHeader(context),
            ..._buildRows(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Palette.grey100,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: _buildHeaderCells(context),
      ),
    );
  }

  List<Widget> _buildHeaderCells(BuildContext context) {
    List<Widget> cells = [];

    // 모바일 감지
    bool isMobile = MediaQuery.of(context).size.width <= 768;

    for (int i = 0; i < headers.length; i++) {
      Widget cell;
      if (i == 0) {
        // 첫 번째 컬럼 (번호 또는 카테고리)
        cell = SizedBox(
          width: isMobile
              ? (headers[0] == "번호" ? 40 : 50) // 모바일에서는 더 작게
              : (headers[0] == "번호" ? 60 : 80),
          child: Text(headers[i], style: _headerTextStyle()),
        );
      } else if (i == headers.length - 1) {
        // 마지막 컬럼 (작성일)
        cell = SizedBox(
          width: isMobile ? 70 : 120, // 모바일에서는 더 작게
          child: Text(headers[i], style: _headerTextStyle()),
        );
      } else {
        // 제목 컬럼 (Notice Board의 제목 또는 FAQ의 질문)
        cell = Expanded(
          child: Text(headers[i], style: _headerTextStyle()),
        );
      }
      cells.add(cell);
    }

    // 관리자일 때 액션 헤더 추가
    if (isAdmin && (onEditTap != null || onDeleteTap != null)) {
      cells.add(
        SizedBox(
          width: 80,
          child: Text("관리", style: _headerTextStyle()),
        ),
      );
    }

    return cells;
  }

  List<Widget> _buildRows(BuildContext context) {
    if (items.isEmpty) {
      return [
        Container(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 14,
                color: Palette.grey600,
                fontFamily: "NotoSansKR",
              ),
            ),
          ),
        ),
      ];
    }

    List<Widget> rows = [];
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isLast = i == items.length - 1;

      rows.add(_buildRow(context, item, i, isLast));

      if (!isLast) {
        rows.add(Divider(height: 1, color: Palette.grey200));
      }
    }

    return rows;
  }

  Widget _buildRow(BuildContext context, Map<String, dynamic> item, int index, bool isLast) {
    return InkWell(
      onTap: () => onItemTap(item),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: isLast
              ? BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: _buildRowCells(context, item, index),
        ),
      ),
    );
  }

  List<Widget> _buildRowCells(BuildContext context, Map<String, dynamic> item, int index) {
    List<Widget> cells = [];

    // 모바일 감지
    bool isMobile = MediaQuery.of(context).size.width <= 768;

    if (headers[0] == "번호") {
      // Notice Board 스타일
      cells.add(
        SizedBox(
          width: isMobile ? 40 : 60, // 모바일에서는 더 작게
          child: Text(
            "${items.length - index}",
            style: TextStyle(
              fontSize: isMobile ? 12 : 14, // 모바일에서는 폰트 크기도 작게
              fontFamily: "NotoSansKR",
              color: Palette.grey600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );

      cells.add(
        Expanded(
          child: Container(
            child: Row(
              children: [
                if (item['isImportant'] ?? false) ...[
                  Icon(Icons.star,
                      color: Palette.primary, size: isMobile ? 14 : 16),
                  SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    item['title'] ?? '',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14, // 모바일에서는 폰트 크기 작게
                      fontFamily: "NotoSansKR",
                      color: Palette.black,
                      fontWeight: (item['isImportant'] ?? false)
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: isMobile ? 2 : 1, // 모바일에서는 두 줄로 표시
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      cells.add(
        SizedBox(
          width: isMobile ? 70 : 120, // 모바일에서는 더 작게
          child: Text(
            item['date'] ?? '',
            style: TextStyle(
              fontSize: isMobile ? 10 : 14, // 모바일에서는 폰트 크기 작게
              fontFamily: "NotoSansKR",
              color: Palette.grey600,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      );
    } else {
      // FAQ Board 스타일
      cells.add(
        SizedBox(
          width: isMobile ? 50 : 80, // 모바일에서는 더 작게
          child: Container(
            padding:
                EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8, vertical: 4),
            decoration: BoxDecoration(
              color: (item['isImportant'] ?? false)
                  ? Palette.primary.withValues(alpha: 0.1)
                  : Palette.grey100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              item['category'] ?? 'FAQ',
              style: TextStyle(
                fontSize: isMobile ? 10 : 12, // 모바일에서는 폰트 크기 작게
                fontFamily: "NotoSansKR",
                color: (item['isImportant'] ?? false)
                    ? Palette.primary
                    : Palette.grey600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );

      cells.add(SizedBox(width: 10));

      cells.add(
        Expanded(
          child: Container(
            child: Row(
              children: [
                if (item['isImportant'] ?? false) ...[
                  Icon(Icons.star,
                      color: Palette.primary, size: isMobile ? 14 : 16),
                  SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    item['title'] ?? '',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14, // 모바일에서는 폰트 크기 작게
                      fontFamily: "NotoSansKR",
                      color: Palette.black,
                      fontWeight: (item['isImportant'] ?? false)
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: isMobile ? 2 : 1, // 모바일에서는 두 줄로 표시
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      cells.add(
        SizedBox(
          width: isMobile ? 70 : 120, // 모바일에서는 더 작게
          child: Text(
            item['date'] ?? '',
            style: TextStyle(
              fontSize: isMobile ? 10 : 14, // 모바일에서는 폰트 크기 작게
              fontFamily: "NotoSansKR",
              color: Palette.grey600,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      );
    }

    // 관리자일 때 액션 버튼 추가
    if (isAdmin && (onEditTap != null || onDeleteTap != null)) {
      cells.add(
        Container(
          width: 80,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onEditTap != null)
                InkWell(
                  onTap: () => onEditTap!(item),
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Palette.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 16,
                      color: Palette.primary,
                    ),
                  ),
                ),
              if (onEditTap != null && onDeleteTap != null) SizedBox(width: 4),
              if (onDeleteTap != null)
                InkWell(
                  onTap: () => onDeleteTap!(item),
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.delete,
                      size: 16,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return cells;
  }

  TextStyle _headerTextStyle() {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      fontFamily: "NotoSansKR",
      color: Palette.grey700,
    );
  }
}
