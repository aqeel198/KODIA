<?php
/*******************************************************
 * almnsa.php
 * سكربت يستقبل الملف من تطبيق Flutter عبر POST،
 * يقوم برفع الملف إلى السيرفر وتخزين بياناته في قاعدة البيانات.
 *******************************************************/

// تفعيل عرض الأخطاء في وضع التطوير (يُنصح بتعطيلها في الإنتاج)
error_reporting(E_ALL);
ini_set('display_errors', 1);
header('Content-Type: text/html; charset=UTF-8');

// استرجاع بيانات الاتصال بقاعدة البيانات من متغيرات البيئة
$servername = getenv('DB_HOST');
$port       = getenv('DB_PORT') ? (int)getenv('DB_PORT') : 3306;
$username   = getenv('DB_USER');
$password   = getenv('DB_PASSWORD');
$dbname     = getenv('DB_NAME');

// التحقق من توفر بيانات الاتصال
if (!$servername || !$username || !$password || !$dbname) {
    die("بيانات الاتصال غير متوفرة. يرجى التأكد من إعداد متغيرات البيئة.");
}

// إنشاء الاتصال بقاعدة البيانات
$conn = new mysqli($servername, $username, $password, $dbname, $port);
if ($conn->connect_error) {
    die("فشل الاتصال بقاعدة البيانات: " . $conn->connect_error);
}
$conn->set_charset("utf8mb4");

// تحديد نوع العملية المطلوبة عبر متغير POST 'action'
$action = isset($_POST['action']) ? $_POST['action'] : 'upload';
echo "Debug: Action = " . $action . "<br>";

if ($action === 'upload') {
    // قبل رفع الملف، نتحقق من صلاحية اشتراك المدرسة
    // نأخذ schoolId من POST
    $schoolId = isset($_POST['schoolId']) ? (int)$_POST['schoolId'] : 0;
    if ($schoolId <= 0) {
        die("schoolId غير صالح.");
    }
    
    // استعلام للتحقق من تاريخ انتهاء الاشتراك
    $stmtSub = $conn->prepare("SELECT subscription_end FROM schools WHERE id = ?");
    if ($stmtSub === false) {
        die("خطأ في التحضير: " . $conn->error);
    }
    $stmtSub->bind_param("i", $schoolId);
    $stmtSub->execute();
    $stmtSub->bind_result($subscription_end);
    if ($stmtSub->fetch()) {
        // مقارنة تاريخ الاشتراك مع تاريخ اليوم
        if (strtotime($subscription_end) < strtotime(date("Y-m-d"))) {
            die("اشتراك المدرسة منتهي، يرجى التجديد.");
        }
    } else {
        die("لم يتم العثور على بيانات المدرسة.");
    }
    $stmtSub->close();

    // عملية رفع الملف
    echo "Debug: POST = ";
    print_r($_POST);
    echo "<br>";

    if (isset($_FILES['file'])) {
        $file         = $_FILES['file'];
        $originalName = $file['name'];
        $tmpName      = $file['tmp_name'];
        $error        = $file['error'];

        // التأكد من أن الملف بصيغة PDF فقط
        $fileExt = strtolower(pathinfo($originalName, PATHINFO_EXTENSION));
        if ($fileExt !== 'pdf') {
            die("يُسمح فقط برفع ملفات PDF.");
        }

        if ($error === 0) {
            // توليد اسم فريد لتفادي التعارض
            $uniqueName = uniqid("pdf_", true) . "." . $fileExt;

            // تحديد المجلد باستخدام $_SERVER['DOCUMENT_ROOT'] وتغييره إلى schoolfile
            $targetDir = $_SERVER['DOCUMENT_ROOT'] . "/schoolfile";
            if (!is_dir($targetDir)) {
                mkdir($targetDir, 0775, true);
            }
            $uploadPath = $targetDir . "/" . $uniqueName;
            echo "Debug: uploadPath = $uploadPath<br>";

            // محاولة نقل الملف من المسار المؤقت إلى المجلد المحدد
            if (move_uploaded_file($tmpName, $uploadPath)) {
                // قراءة البيانات الإضافية من POST
                $providedFileName = isset($_POST['fileName']) ? $_POST['fileName'] : $uniqueName;
                $folderId         = isset($_POST['folderId']) ? (int)$_POST['folderId'] : 0;
                $userId           = isset($_POST['userId']) ? (int)$_POST['userId'] : 0;
                // $schoolId موجود مسبقاً

                echo "Debug: fileName = $providedFileName, folderId = $folderId, userId = $userId, schoolId = $schoolId<br>";

                // تحديد المسار النصي (نسبي) لتخزينه في قاعدة البيانات
                $filePathDB = "schoolfile/" . $uniqueName;

                // إدخال البيانات في جدول files (بما في ذلك schoolId)
                $stmt = $conn->prepare("INSERT INTO files (fileName, filePath, folderId, userId, schoolId) VALUES (?, ?, ?, ?, ?)");
                if ($stmt === false) {
                    die("خطأ في التحضير: " . $conn->error);
                }
                $stmt->bind_param("ssiii", $providedFileName, $filePathDB, $folderId, $userId, $schoolId);
                if ($stmt->execute()) {
                    echo "تم رفع الملف '$providedFileName' وتخزين بياناته بنجاح.";
                } else {
                    echo "حدث خطأ في حفظ بيانات الملف: " . $stmt->error;
                }
                $stmt->close();
            } else {
                echo "حدث خطأ أثناء نقل الملف من المسار المؤقت.";
            }
        } else {
            echo "حدث خطأ في رفع الملف. رمز الخطأ: $error";
        }
    } else {
        echo "لم يتم اختيار ملف للرفع.";
    }
} elseif ($action === 'delete') {
    // عملية حذف ملف
    // يجب إرسال معرف الملف (id) والمسار النسبي للملف (filePath)
    $fileId     = isset($_POST['id']) ? (int)$_POST['id'] : 0;
    $filePathDB = isset($_POST['filePath']) ? $_POST['filePath'] : '';

    if ($fileId <= 0 || empty($filePathDB)) {
        die("بيانات الحذف غير كاملة.");
    }

    // حذف الملف من نظام الملفات
    $fullPath = $_SERVER['DOCUMENT_ROOT'] . "/" . $filePathDB;
    if (file_exists($fullPath)) {
        if (!unlink($fullPath)) {
            echo "حدث خطأ أثناء حذف الملف من النظام.<br>";
        } else {
            echo "تم حذف الملف من النظام.<br>";
        }
    } else {
        echo "الملف غير موجود في النظام.<br>";
    }

    // حذف سجل الملف من قاعدة البيانات
    $stmt = $conn->prepare("DELETE FROM files WHERE id = ?");
    if ($stmt === false) {
        die("خطأ في التحضير: " . $conn->error);
    }
    $stmt->bind_param("i", $fileId);
    if ($stmt->execute()) {
        echo "تم حذف سجل الملف من قاعدة البيانات بنجاح.";
    } else {
        echo "حدث خطأ أثناء حذف سجل الملف: " . $stmt->error;
    }
    $stmt->close();
} elseif ($action === 'update') {
    // عملية تعديل بيانات الملف
    // يجب إرسال معرف الملف (id) والبيانات الجديدة مثل fileName و filePath
    $fileId      = isset($_POST['id']) ? (int)$_POST['id'] : 0;
    $newFileName = isset($_POST['fileName']) ? $_POST['fileName'] : '';
    $newFilePath = isset($_POST['filePath']) ? $_POST['filePath'] : '';

    if ($fileId <= 0 || empty($newFileName) || empty($newFilePath)) {
        die("بيانات التعديل غير كاملة.");
    }

    echo "Debug: تحديث الملف مع id = $fileId, newFileName = $newFileName, newFilePath = $newFilePath<br>";

    $stmt = $conn->prepare("UPDATE files SET fileName = ?, filePath = ? WHERE id = ?");
    if ($stmt === false) {
        die("خطأ في التحضير: " . $conn->error);
    }
    $stmt->bind_param("ssi", $newFileName, $newFilePath, $fileId);
    if ($stmt->execute()) {
        echo "تم تحديث بيانات الملف بنجاح.";
    } else {
        echo "حدث خطأ أثناء تحديث بيانات الملف: " . $stmt->error;
    }
    $stmt->close();
} else {
    echo "إجراء غير معروف.";
}

$conn->close();
?>
