import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/AdminTeacherScheduleTab.dart';
import 'package:gi_english_website/pages/StudentDetailPage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/PhoneUtil.dart';

/// 회원관리.
/// 메인 관리자: 내 스케줄 / 내 수강생 / 전체 스케줄 / 모든 수강생.
/// 강사: 내 스케줄 / 내 수강생.
class AdminMembersHubPage extends StatelessWidget {
  final AdminRole role;
  final Widget mySchedule;
  final Widget myStudents;

  const AdminMembersHubPage({
    Key? key,
    required this.role,
    required this.mySchedule,
    required this.myStudents,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isOwner = role == AdminRole.owner;
    return DefaultTabController(
      length: isOwner ? 4 : 2,
      child: Column(
        children: [
          Material(
            color: Palette.white,
            elevation: 0,
            child: TabBar(
              isScrollable: true,
              indicatorColor: Palette.navy,
              labelColor: Palette.navy,
              unselectedLabelColor: Palette.grey500,
              labelStyle: TextStyle(
                  fontFamily: "NotoSansKR", fontWeight: FontWeight.bold),
              tabs: [
                const Tab(text: '내 스케줄'),
                const Tab(text: '내 수강생 관리'),
                if (isOwner) const Tab(text: '전체 스케줄'),
                if (isOwner) const Tab(text: '모든 수강생 관리'),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              children: [
                mySchedule,
                myStudents,
                if (isOwner) const AdminTeacherScheduleTab(schoolOverview: true),
                if (isOwner) const AllStudentsPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AllStudentsPanel extends StatefulWidget {
  const AllStudentsPanel({Key? key}) : super(key: key);

  @override
  State<AllStudentsPanel> createState() => _AllStudentsPanelState();
}

class _AllStudentsPanelState extends State<AllStudentsPanel> {
  static const int _pageSize = 20;

  List<Map<String, dynamic>> _members = [];
  Map<String, String> _teacherNames = {};
  bool _loading = true;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final members = await AuthService.listMembers(
      limit: 2000,
      oldestFirst: true,
    );
    final teachers = await AuthService.listTeachers();
    if (!mounted) return;
    setState(() {
      _members = members;
      _teacherNames = {
        for (final teacher in teachers)
          if ((teacher['uid']?.toString() ?? '').isNotEmpty)
            teacher['uid'].toString(): teacher['name']?.toString() ?? '',
      };
      final lastPage = _lastPage;
      if (_page > lastPage) _page = lastPage;
      _loading = false;
    });
  }

  int get _lastPage {
    if (_members.isEmpty) return 0;
    return ((_members.length - 1) / _pageSize).floor();
  }

  String _teacherLabel(Map<String, dynamic> member) {
    final name = AuthService.memberTeacherName(member, teacherNames: _teacherNames);
    return name.isEmpty ? '미배정' : name;
  }

  Future<void> _openDetail(Map<String, dynamic> member) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentDetailPage(
          member: member,
          teacherName: _teacherLabel(member),
        ),
      ),
    );
    if (!mounted) return;
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final start = _page * _pageSize;
    final end = (_page + 1) * _pageSize > _members.length
        ? _members.length
        : (_page + 1) * _pageSize;
    final pageItems =
        _members.isEmpty ? const <Map<String, dynamic>>[] : _members.sublist(start, end);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('모든 수강생', style: TextStyle(fontFamily: "Jalnan", fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            '가입한 순서대로 쌓입니다. 담당 강사를 확인하고, 수강생을 누르면 수강·결제 정보를 볼 수 있습니다.',
            style: TextStyle(
                fontFamily: "NotoSansKR", fontSize: 13, color: Palette.grey600),
          ),
          const SizedBox(height: 8),
          Text(
            _members.isEmpty
                ? '가입 회원 0명'
                : '전체 ${_members.length}명 · ${start + 1}–$end번째',
            style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Palette.secondaryDark),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_members.isEmpty)
            Text('가입된 수강생이 없습니다.',
                style:
                    TextStyle(fontFamily: "NotoSansKR", color: Palette.grey500))
          else ...[
            ...pageItems.asMap().entries.map((entry) {
              final index = start + entry.key;
              return _studentTile(entry.value, index + 1);
            }),
            const SizedBox(height: 12),
            _pager(),
          ],
        ],
      ),
    );
  }

  Widget _studentTile(Map<String, dynamic> member, int order) {
    final name = member['name']?.toString().trim() ?? '';
    final email = member['email']?.toString().trim() ?? '';
    final phone = member['phone']?.toString() ?? '';
    final joined = AuthService.memberCreatedAt(member);
    final teacher = _teacherLabel(member);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => _openDetail(member),
        leading: CircleAvatar(
          backgroundColor: Palette.navy,
          foregroundColor: Palette.white,
          child: Text('$order',
              style: TextStyle(fontFamily: "NotoSansKR", fontSize: 12)),
        ),
        title: Text(
          name.isEmpty ? '이름 미등록 회원' : name,
          style: TextStyle(
              fontFamily: "NotoSansKR", fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          [
            if (email.isNotEmpty) email,
            if (PhoneUtil.isValid(phone)) PhoneUtil.display(phone),
            '가입 ${_formatDate(joined)}',
          ].join(' · '),
          style: TextStyle(
              fontFamily: "NotoSansKR", fontSize: 12, color: Palette.grey600),
        ),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Text(
            teacher,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: teacher == '미배정' ? Palette.grey500 : Palette.secondaryDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _pager() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: _page == 0 ? null : () => setState(() => _page -= 1),
          child: Text('이전', style: TextStyle(fontFamily: "NotoSansKR")),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '${_page + 1} / ${_lastPage + 1}',
            style: TextStyle(
                fontFamily: "NotoSansKR", fontWeight: FontWeight.bold),
          ),
        ),
        TextButton(
          onPressed: _page >= _lastPage ? null : () => setState(() => _page += 1),
          child: Text('다음', style: TextStyle(fontFamily: "NotoSansKR")),
        ),
      ],
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}.${two(dt.month)}.${two(dt.day)}';
  }
}
