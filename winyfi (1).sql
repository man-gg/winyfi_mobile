-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jul 05, 2025 at 04:55 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `winyfi`
--

-- --------------------------------------------------------

--
-- Table structure for table `routers`
--

CREATE TABLE `routers` (
  `id` int(11) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `ip_address` varchar(100) DEFAULT NULL,
  `mac_address` varchar(100) DEFAULT NULL,
  `brand` varchar(100) DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `last_seen` datetime DEFAULT NULL,
  `image_path` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `routers`
--

INSERT INTO `routers` (`id`, `name`, `ip_address`, `mac_address`, `brand`, `location`, `last_seen`, `image_path`) VALUES
(1, 'Server', '192.168.1.1', '00:18:93:dc:a9:c6\n', 'ewan', 'home', '2025-07-04 16:28:27', 'C:/Users/63967/Pictures/Screenshots/Screenshot 2023-08-28 204402.png'),
(7, 'AP 1', '192.168.1.100', 'adfaefawefaw', 'huawei', 'home', '2025-07-01 07:36:42', NULL),
(8, 'samsung', '192.168.1.57', 'dfadfa', 'fasdfaadfaffasd', 'asdfas', '2025-07-04 16:23:17', ''),
(10, 'iphone', '192.168.1.46', 'dsdas', 'dasd', 'guiuijh', '2025-06-28 13:39:12', NULL),
(11, 'vhbjnmk', '192.168.128.163', 'ybjnk', 'ejwefvj', 'jaijvnj', '2025-06-30 08:54:29', 'C:/Users/63967/Pictures/Screenshots/Screenshot 2023-08-28 204402.png');

-- --------------------------------------------------------

--
-- Table structure for table `router_status_log`
--

CREATE TABLE `router_status_log` (
  `id` int(11) NOT NULL,
  `router_id` int(11) DEFAULT NULL,
  `status` enum('online','offline') DEFAULT NULL,
  `timestamp` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `router_status_log`
--

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `first_name` varchar(50) NOT NULL,
  `last_name` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('admin','user') NOT NULL DEFAULT 'user',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `first_name`, `last_name`, `password_hash`, `role`, `created_at`) VALUES
(2, 'admin', 'ADMIN', '', 'pbkdf2:sha256:1000000$sksYDmeDqPvJtFJ2$983e5d84b4b871ca3747f6acb0445ba9a02839ec4986688f2b7ec81ab47717df', 'admin', '2025-07-04 03:42:03'),
(3, 'cjay', 'Cjay Pogi', 'Arano', 'scrypt:32768:8:1$74j3QllQhm1iEG6f$4f15ad7181b93fba41c7f0864705f5fd7539e512d1ecb08d246736baa92bfe93100e665fd1dbd70e482473c4c23e7cfdc1bbb031823e03d3b9cc0db6416845e1', 'user', '2025-07-04 05:12:34');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `routers`
--
ALTER TABLE `routers`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `router_status_log`
--
ALTER TABLE `router_status_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `router_id` (`router_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `routers`
--
ALTER TABLE `routers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `router_status_log`
--
ALTER TABLE `router_status_log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2971;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `router_status_log`
--
ALTER TABLE `router_status_log`
  ADD CONSTRAINT `router_status_log_ibfk_1` FOREIGN KEY (`router_id`) REFERENCES `routers` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
