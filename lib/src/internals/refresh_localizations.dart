// ignore_for_file: unnecessary_this
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 刷新组件的国际化支持
///
/// 该文件提供了刷新组件所需的多语言支持，包括：
/// - 中文、英文、法语、俄语、乌克兰语、意大利语、日语
/// - 德语、西班牙语、荷兰语、瑞典语、葡萄牙语和韩语
///
/// 示例用法：
/// ```dart
/// void main() {
///   runApp(
///     MaterialApp(
///       localizationsDelegates: [
///         RefreshLocalizations.delegate,
///         GlobalMaterialLocalizations.delegate,
///         GlobalWidgetsLocalizations.delegate,
///         GlobalCupertinoLocalizations.delegate,
///       ],
///       supportedLocales: [
///         const Locale('en'), // 英语
///         const Locale('zh'), // 中文
///         // 其他支持的语言
///       ],
///       home: MyHomePage(),
///     ),
///   );
/// }
/// ```

/// 下拉刷新组件的国际化支持类
///
/// 提供多语言支持，包括中文、英文、法语、俄语、乌克兰语、意大利语、日语、德语、西班牙语、荷兰语、瑞典语、葡萄牙语和韩语
class RefreshLocalizations {
  /// 当前本地化语言环境
  final Locale locale;

  /// 构造函数
  ///
  /// - [locale]: 当前语言环境
  RefreshLocalizations(this.locale);

  /// 支持的语言映射表
  ///
  /// 键为语言代码，值为对应语言的刷新字符串实现
  static const Map<String, RefreshString Function()> _languageBuilders = {
    'en': EnRefreshString.new,
    'zh': ChRefreshString.new,
    'fr': FrRefreshString.new,
    'ru': RuRefreshString.new,
    'uk': UkRefreshString.new,
    'it': ItRefreshString.new,
    'ja': JpRefreshString.new,
    'de': DeRefreshString.new,
    'es': EsRefreshString.new,
    'nl': NlRefreshString.new,
    'sv': SvRefreshString.new,
    'pt': PtRefreshString.new,
    'ko': KrRefreshString.new,
  };

  /// 语言实例缓存
  static final Map<String, RefreshString> _cache = {};

  /// 获取当前语言的刷新字符串实例
  ///
  /// 如果当前语言不被支持，返回英文实例
  RefreshString get currentLocalization {
    final languageCode = locale.languageCode;
    // 从缓存中获取，不存在则创建并缓存
    return _cache.putIfAbsent(
      languageCode,
      () => _languageBuilders[languageCode]?.call() ?? EnRefreshString(),
    );
  }

  /// 刷新本地化代理
  static const RefreshLocalizationsDelegate delegate = RefreshLocalizationsDelegate();

  /// 从上下文获取刷新本地化实例
  ///
  /// - [context]: 上下文
  /// - 返回值: 刷新本地化实例
  static RefreshLocalizations? of(BuildContext context) {
    return Localizations.of(context, RefreshLocalizations);
  }
}

/// 刷新本地化代理类
///
/// 负责加载和管理刷新组件的本地化资源
class RefreshLocalizationsDelegate extends LocalizationsDelegate<RefreshLocalizations> {
  /// 支持的语言列表
  static const supportedLanguages = ['en', 'zh', 'fr', 'ru', 'uk', 'ja', 'it', 'de', 'ko', 'pt', 'sv', 'nl', 'es'];

  /// 构造函数
  const RefreshLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return supportedLanguages.contains(locale.languageCode);
  }

  @override
  Future<RefreshLocalizations> load(Locale locale) {
    return SynchronousFuture<RefreshLocalizations>(RefreshLocalizations(locale));
  }

  @override
  bool shouldReload(LocalizationsDelegate<RefreshLocalizations> old) {
    return false;
  }
}

/// 刷新字符串接口
///
/// 定义了刷新组件所需的所有本地化字符串
abstract class RefreshString {
  /// 下拉刷新空闲状态文本
  String? idleRefreshText;

  /// 下拉刷新可释放刷新状态文本
  String? canRefreshText;

  /// 下拉刷新中状态文本
  String? refreshingText;

  /// 下拉刷新完成状态文本
  String? refreshCompleteText;

  /// 下拉刷新失败状态文本
  String? refreshFailedText;


  /// 上拉加载空闲状态文本
  String? idleLoadingText;

  /// 上拉加载可释放加载状态文本
  String? canLoadingText;

  /// 上拉加载中状态文本
  String? loadingText;

  /// 上拉加载失败状态文本
  String? loadFailedText;

  /// 上拉加载无更多数据状态文本
  String? noMoreText;
}

/// Chinese
class ChRefreshString implements RefreshString {
  @override
  String? canLoadingText = "松手开始加载数据";

  @override
  String? canRefreshText = "松开开始刷新数据";

  @override
  String? idleLoadingText = "上拉加载";

  @override
  String? idleRefreshText = "下拉刷新";

  @override
  String? loadFailedText = "加载失败";

  @override
  String? loadingText = "加载中…";

  @override
  String? noMoreText = "没有更多数据了";

  @override
  String? refreshCompleteText = "刷新成功";

  @override
  String? refreshFailedText = "刷新失败";

  @override
  String? refreshingText = "刷新中…";
}

/// English
class EnRefreshString implements RefreshString {
  @override
  String? canLoadingText = "Release to load more";

  @override
  String? canRefreshText = "Release to refresh";

  @override
  String? idleLoadingText = "Pull up Load more";

  @override
  String? idleRefreshText = "Pull down Refresh";

  @override
  String? loadFailedText = "Load Failed";

  @override
  String? loadingText = "Loading…";

  @override
  String? noMoreText = "No more data";

  @override
  String? refreshCompleteText = "Refresh completed";

  @override
  String? refreshFailedText = "Refresh failed";

  @override
  String? refreshingText = "Refreshing…";
}

/// French
class FrRefreshString implements RefreshString {
  @override
  String? canLoadingText = "Relâchez pour charger davantage";

  @override
  String? canRefreshText = "Relâchez pour rafraîchir";

  @override
  String? idleLoadingText = "Tirez pour charger davantage";

  @override
  String? idleRefreshText = "Tirez pour rafraîchir";

  @override
  String? loadFailedText = "Chargement échoué";

  @override
  String? loadingText = "Chargement…";

  @override
  String? noMoreText = "Aucune autre donnée";

  @override
  String? refreshCompleteText = "Rafraîchissement terminé";

  @override
  String? refreshFailedText = "Rafraîchissement échoué";

  @override
  String? refreshingText = "Rafraîchissement…";
}

/// Russian
class RuRefreshString implements RefreshString {
  @override
  String? canLoadingText = "Отпустите, чтобы загрузить больше";

  @override
  String? canRefreshText = "Отпустите, чтобы обновить";

  @override
  String? idleLoadingText = "Тянуть вверх, чтобы загрузить больше";

  @override
  String? idleRefreshText = "Тянуть вниз, чтобы обновить";

  @override
  String? loadFailedText = "Ошибка загрузки";

  @override
  String? loadingText = "Загрузка…";

  @override
  String? noMoreText = "Больше данных нет";

  @override
  String? refreshCompleteText = "Обновление завершено";

  @override
  String? refreshFailedText = "Не удалось обновить";

  @override
  String? refreshingText = "Обновление…";
}

// Ukrainian
class UkRefreshString implements RefreshString {
  @override
  String? canLoadingText = "Відпустіть, щоб завантажити більше";

  @override
  String? canRefreshText = "Відпустіть, щоб оновити";

  @override
  String? idleLoadingText = "Тягнути вгору, щоб завантажити більше";

  @override
  String? idleRefreshText = "Тягнути вниз, щоб оновити";

  @override
  String? loadFailedText = "Помилка завантаження";

  @override
  String? loadingText = "Завантаження…";

  @override
  String? noMoreText = "Більше даних немає";

  @override
  String? refreshCompleteText = "Оновлення завершено";

  @override
  String? refreshFailedText = "Не вдалося оновити";

  @override
  String? refreshingText = "Оновлення…";
}

/// Italian
class ItRefreshString implements RefreshString {
  @override
  String? canLoadingText = "Rilascia per caricare altro";

  @override
  String? canRefreshText = "Rilascia per aggiornare";

  @override
  String? idleLoadingText = "Tira per caricare altro";

  @override
  String? idleRefreshText = "Tira giù per aggiornare";

  @override
  String? loadFailedText = "Caricamento fallito";

  @override
  String? loadingText = "Caricamento…";

  @override
  String? noMoreText = "Nessun altro elemento";

  @override
  String? refreshCompleteText = "Aggiornamento completato";

  @override
  String? refreshFailedText = "Aggiornamento fallito";

  @override
  String? refreshingText = "Aggiornamento…";
}

/// Japanese
class JpRefreshString implements RefreshString {
  @override
  String? canLoadingText = "指を離して更に読み込む";

  @override
  String? canRefreshText = "指を離して更新";

  @override
  String? idleLoadingText = "上方スワイプで更に読み込む";

  @override
  String? idleRefreshText = "下方スワイプでデータを更新";

  @override
  String? loadFailedText = "読み込みが失敗しました";

  @override
  String? loadingText = "読み込み中…";

  @override
  String? noMoreText = "データはありません";

  @override
  String? refreshCompleteText = "更新完了";

  @override
  String? refreshFailedText = "更新が失敗しました";

  @override
  String? refreshingText = "更新中…";
}

/// German
class DeRefreshString implements RefreshString {
  @override
  String? canLoadingText = "Loslassen, um mehr zu laden";

  @override
  String? canRefreshText = "Zum Aktualisieren loslassen";

  @override
  String? idleLoadingText = "Hochziehen, mehr laden";

  @override
  String? idleRefreshText = "Ziehen für Aktualisierung";

  @override
  String? loadFailedText = "Laden ist fehlgeschlagen";

  @override
  String? loadingText = "Lade…";

  @override
  String? noMoreText = "Keine weitere Daten";

  @override
  String? refreshCompleteText = "Aktualisierung fertig";

  @override
  String? refreshFailedText = "Aktualisierung fehlgeschlagen";

  @override
  String? refreshingText = "Aktualisiere…";
}

/// Spanish
class EsRefreshString implements RefreshString {
  @override
  String? canLoadingText = "Suelte para cargar más";

  @override
  String? canRefreshText = "Suelte para actualizar";

  @override
  String? idleLoadingText = "Tire hacia arriba para cargar más";

  @override
  String? idleRefreshText = "Tire hacia abajo para refrescar";

  @override
  String? loadFailedText = "Error de carga";

  @override
  String? loadingText = "Cargando…";

  @override
  String? noMoreText = "No hay más datos disponibles";

  @override
  String? refreshCompleteText = "Actualización completada";

  @override
  String? refreshFailedText = "Error al actualizar";

  @override
  String? refreshingText = "Actualizando…";
}

/// Dutch
class NlRefreshString implements RefreshString {
  @override
  String? canLoadingText = "Laat los om meer te laden";

  @override
  String? canRefreshText = "Laat los om te vernieuwen";

  @override
  String? idleLoadingText = "Trek omhoog om meer te laden";

  @override
  String? idleRefreshText = "Trek omlaag om te vernieuwen";

  @override
  String? loadFailedText = "Laden mislukt";

  @override
  String? loadingText = "Laden…";

  @override
  String? noMoreText = "Geen data meer";

  @override
  String? refreshCompleteText = "Vernieuwen voltooid";

  @override
  String? refreshFailedText = "Vernieuwen mislukt";

  @override
  String? refreshingText = "Vernieuwen…";
}

/// Swedish
class SvRefreshString implements RefreshString {
  @override
  String? canLoadingText = "Släpp för att ladda mer";

  @override
  String? canRefreshText = "Släpp för att uppdatera";

  @override
  String? idleLoadingText = "Dra upp för att ladda mer";

  @override
  String? idleRefreshText = "Dra ner för att uppdatera";

  @override
  String? loadFailedText = "Hämtningen misslyckades";

  @override
  String? loadingText = "Laddar…";

  @override
  String? noMoreText = "Ingen mer data";

  @override
  String? refreshCompleteText = "Uppdaterad";

  @override
  String? refreshFailedText = "Kunde inte uppdatera";

  @override
  String? refreshingText = "Uppdaterar…";
}

// Portuguese - Brazil
class PtRefreshString implements RefreshString {
  @override
  String? canLoadingText = "Solte para carregar mais";

  @override
  String? canRefreshText = "Solte para atualizar";


  @override
  String? idleLoadingText = "Puxe para cima para carregar mais";

  @override
  String? idleRefreshText = "Puxe para baixo para atualizar";

  @override
  String? loadFailedText = "Falha ao carregar";

  @override
  String? loadingText = "Carregando…";

  @override
  String? noMoreText = "Não há mais dados";

  @override
  String? refreshCompleteText = "Atualização completada";

  @override
  String? refreshFailedText = "Falha ao atualizar";

  @override
  String? refreshingText = "Atualizando…";
}

/// Korean
class KrRefreshString implements RefreshString {
  @override
  String? canLoadingText = "당겨서 불러오기";

  @override
  String? canRefreshText = "당겨서 새로 고침";

  @override
  String? idleLoadingText = "위로 당겨서 불러오기";

  @override
  String? idleRefreshText = "아래로 당겨서 새로 고침";

  @override
  String? loadFailedText = "로딩에 실패했습니다.";

  @override
  String? loadingText = "로딩 중…";

  @override
  String? noMoreText = "데이터가 더 이상 없습니다.";

  @override
  String? refreshCompleteText = "새로 고침 완료";

  @override
  String? refreshFailedText = "새로 고침에 실패했습니다.";

  @override
  String? refreshingText = "새로 고침 중…";
}
